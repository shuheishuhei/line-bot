
desc "This task is called by the Heroku scheduler add-on" #タスクの説明のためにdescメソッドを使うことができる。
task :update_feed => :environment do
  require 'line/bot' #gem 'line-bot-api'
  require 'open-uri'
  require 'kconv'
  require 'rexml/document' #天気情報のページのxmlファイルを読み込んでいる

  # 下記はline-bot側の設定をしている。 ENV["LINE_CHANNNEL_SECRET"]とENV["LINE_CHANNEL_TOKEN"]の部分には、herokuにアップロード後にそれぞれのキーを挿入する
  client ||= Line::Bot::Client.new { |config|
    config.channel_secret = ENV["LINE_CHANNEL_SECRET"]
    config.channel_token = ENV["LINE_CHANNEL_TOKEN"]
  }

  #使用したxmlデータ(毎日朝6時更新):以下URLを入力すれば見ることができる。
  url = "https://www.drk7.jp/weather/xml/27.xml"
  # xmlデータをパース(利用しやすいように整形)
  xml = open( url ).read.toutf8
  doc = REXML::document.new(xml)
  # パスの共通部分を変数化(area[4]は「東京地方」を指定している)
  xpath = 'weatherforecast/pref/area[1]/info/rainfallchance/'
  # 6~12時の降水確率(以下同等)
  per06to12 = doc.elements[xpath + 'period[2]'].text
  per12to18 = doc.elements[xpath + 'period[3]'].text
  per18to24 = doc.elements[xpath + 'period[4]'].text
  # メッセージを発信する降水確率の下限値の設定
  min_per = 20
  if per06to12.to_i >- min_per || per12to18.to_i >= min_per || per18to24.to_i >= min_per
    word1 =
      ["いい朝だね",
       "今日もよく眠れた?",
       "二日酔い大丈夫?",
       "早起きしてえらいね!",
       "いつもより起きるのちょっと遅いんじゃない?"].sample
    word2 =
      ["気をつけて行ってきてね",
       "良い1日を過ごしてね",
       "雨に負けずに今日も頑張ってね"
       "今日も一日楽しんでいこうね",
       "楽しいことがありますように"].sample
    # 降水確率によってメッセージを変更する閾値の設定
    mid_per = 50
    if per06to12.to_i >= mid_per || per12to18.to_i >= mid_per || per18to24.to_i mid_per
      word3 = "今日は雨が降りそうだから傘を忘れないでね"
    else
      word3 = "今日は雨が降るかもしれないから折り畳み傘があると安心だよ"
    end
    # 発信するメッセージの設定
    push =
      "#{word1}\n#{word3}\n降水確率はこんな感じだよ。\n  6〜12時 #{per06to12}%\n 12〜18時  #{per12to18}%\n  18〜24時 #{per18to24}%\n#{word2}"
    user_ids = User.all.pluck(:line_id)
    message = {
      type: 'text',
      text: push
    }
    response = client.multicast(user_ids, message)
  end
  "OK"
end  