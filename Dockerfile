FROM ruby:latest
RUN apt update -qqy &&  \
apt install -qqy locales locales-all
ADD . /opt/simekiri
WORKDIR /opt/simekiri
ENV LANG ja_JP.UTF-8
RUN bundle install --path vendor/bundle
CMD bundle exec ruby simekiri.rb
