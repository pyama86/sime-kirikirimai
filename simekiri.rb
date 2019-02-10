# coding: utf-8
require 'octokit'
require 'google/apis/calendar_v3'
require 'googleauth'
require 'googleauth/stores/file_token_store'
require 'fileutils'
require "pp"

APPLICATION_NAME = 'SimeKiririkiMai'.freeze
TIME_ZONE = 'Japan'
SCOPE = 'https://www.googleapis.com/auth/calendar'
OOB_URI = 'urn:ietf:wg:oauth:2.0:oob'.freeze
CREDENTIALS_PATH = 'credential.json'.freeze
TOKEN_PATH = 'token.yaml'.freeze

def client
  @_client ||= Octokit::Client.new(
    api_endpoint: (ENV['GITHUB_API'] || "https://api.github.com"),
    access_token: ENV['GITHUB_TOKEN'],
    auto_paginate: true,
    per_page: 300
  )
  @_client
end

def mention_to_addresses(mention)
  if mention =~ /\//
    org, tname = mention.split(/\//)
    t = client.organization_teams(org, name: tname).select do |t|
      t[:slug] == tname
    end
    client.team_members(t.first[:id]).map do |m|
      mention_to_addresses(m[:login])
    end
  else
    client.user(mention).email
  end
rescue
  nil
end

def filter_issues_by_repos(repos)
  repos.each_with_object([]) do |repo,r|
    puts "fetch #{repo.full_name}"
    # 時差が9時間+1時間前の更新を対象にする
    client.issues(repo.full_name, state: 'open', since:  (Time.new - 3600 * 10).iso8601).each do |issue|
      if issue.title =~ (/(締切|締め切り)/)
        m = issue.title.match(/(\d{4}\/)?(\d{1,2}\/\d{1,2})(\s\d{1,2}:\d{1,2})?/)
        next unless m

        year = (m[1] && !m[1].empty?) ? m[1] : "#{Date.today.year}/"
        date = "#{year}#{m[2]}"
        time = m[3]
        puts " match issue #{issue.title}"
        addresses = issue.body.scan(/\@(\S+)/).push(issue.user.login).flatten.map do |m|
          mention_to_addresses(m)
        end

        r << {
          title: issue.title,
          url: issue.html_url,
          members: addresses.flatten.compact,
          date: date,
          time: time,
        }
      end
    end
  end
end

def limiters
  r = client.organizations.map do |o|
    filter_issues_by_repos(client.organization_repositories(o.login))
  end
  r << filter_issues_by_repos(client.list_repos(client.user.login))
  r.flatten.compact
end

def authorize
  client_id = Google::Auth::ClientId.from_file(CREDENTIALS_PATH)
  token_store = Google::Auth::Stores::FileTokenStore.new(file: TOKEN_PATH)
  authorizer = Google::Auth::UserAuthorizer.new(client_id, SCOPE, token_store)
  user_id = 'default'
  credentials = authorizer.get_credentials(user_id)
  if credentials.nil?
    url = authorizer.get_authorization_url(base_url: OOB_URI)
    puts 'Open the following URL in the browser and enter the ' \
      "resulting code after authorization:\n" + url
    code = gets
    credentials = authorizer.get_and_store_credentials_from_code(
      user_id: user_id, code: code, base_url: OOB_URI
    )
  end
  credentials
end

def service
  unless @_service
    @_service = Google::Apis::CalendarV3::CalendarService.new
    @_service.client_options.application_name = APPLICATION_NAME
    @_service.authorization = authorize
  end
  @_service
end

def fetch_event(time)
  service.list_events(ENV['GOOGLE_CALENDER_ID'],
                      max_results: 40,
                      single_events: true,
                      order_by: 'startTime',
                      time_min: time)
end
def add_event(param, date)
  h = {
    summary: param[:title],
    description: "from Github:#{param[:url]}",
    location: "",
    attendees: param[:members].map {|a| {email: a}},
    start: {
      time_zone: TIME_ZONE
    },
    end: {
      time_zone: TIME_ZONE
    }
  }

  c = date.instance_of?(Date) ? :date : :date_time
  h[:start][c] = date.to_s
  h[:end][c] = date.to_s

  event = Google::Apis::CalendarV3::Event.new(h)
  # new
  # 終日が取得できないケースがあるので、一日前を最小検索範囲とする
  items = fetch_event(((date-1).to_time).iso8601).items
  if items.empty? || !(ce = items.find {|e| e.summary == param[:title] })
    service.insert_event(ENV['GOOGLE_CALENDER_ID'] , event)
  # update
  elsif ce.attendees && ce.attendees.map { |a| a.email }.sort.uniq != param[:members].sort.uniq
    service.patch_event(ENV['GOOGLE_CALENDER_ID'] , ce.id, event)
  end
end
# auth
service
puts "fetch start"
limiters.each do |l|
  date = if l[:time]
           DateTime.parse("#{l[:date]} #{l[:time]}:00") - Rational(9, 24)
         else
           Date.parse(l[:date])
         end
  add_event(l, date)
end
