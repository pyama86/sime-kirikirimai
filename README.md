# Simekirikirimai
GithubのIssueタイトルからGoogleカレンダーに締め切りを設定します。

# 出来ること
GithubのIssueのタイトルから締切日を取得し、Issueの起票者、Issueの本文でメンションが飛んでいるメンバーを参加者とした予定を作成します。またグループメンションにも対応しています。

# 動作条件
1. GithubIssueのタイトルに[締切]、もしくは[締め切り]を含み、日時っぽい文字列がある([yyyy/mm/dd] or [mm/dd] or [yyyy/mm/dd/ hh:mi] or [mm/dd hh:mi])
2. 予定を追加するメンバーがGithubの[メールアドレスを公開](https://github.com/settings/profile)している。

# 利用方法
```
# Please change api when using with ghe GITHUB_API
docker run -e GITHUB_TOKEN=$(GITHUB_TOKEN) \
  -e GOOGLE_CALENDER_ID=$(GOOGLE_CALENDER_ID) \
  -v `pwd`/credential.json:/opt/simekiri/credential.json \
  -v `pwd`/token.yaml:/opt/simekiri/token.yaml \
  -it pyama/simekirikirimai:0.0.1
```
