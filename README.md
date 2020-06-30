OmniAuthを使って見る
===================

以前[twitter_oauthというgemを使ってTwitter認証を試した](https://github.com/tyfkda/twitter-oauth-test)
が、他のウェブサービスを使って認証もしてみたいので、
[OmniAuth](https://github.com/intridea/omniauth#integrating-omniauth-into-your-application)
というgemを使ってみることにする。

OmniAuthでググるとRailsを使ったサンプルばかりが引っかかって、よりシンプルな使い方が
なかなか探しづらかったのだが、
[An example sinatra omniauth client app](https://gist.github.com/fairchild/1442227)
を参考にしたらできた。

アプリはHerokuを使ってデプロイする。言語はRuby、フレームワークはSinatraを使う。

[コード](https://github.com/tyfkda/omniauth-test), [デモ](https://omniauth-github-tyfkda-test.herokuapp.com/)
[![Deploy](https://www.herokucdn.com/deploy/button.png)](https://heroku.com/deploy?template=https://github.com/tyfkda/omniauth-test.git)

### OmniAuthのセットアップ

`Gemfile`に必要なファイルを追加する：

Gemfile

```rb:Gemfile
source 'https://rubygems.org'
gem 'sinatra'
gem 'omniauth'
gem 'omniauth-oauth2'
gem 'omniauth-twitter'
gem 'json'
```

* JSONは認証結果を分かりやすく表示するためだけに使っていて、実際には必要ない
* `omniauth-oauth2`を追加しないと `NoMethod join for String` などというエラーが
  出てしまい、動かなかった

app.rb

```rb:app.rb
require 'rubygems'
require 'sinatra'
require 'omniauth'
require 'omniauth-twitter'

class SinatraApp < Sinatra::Base
  configure do
    set :sessions, true
    set :inline_templates, true
  end

  use OmniAuth::Builder do
    provider :twitter, ENV['TWITTER_KEY'], ENV['TWITTER_SECRET']
  end

  get '/' do
    erb "<a href='/auth/twitter'>Login with Twitter</a><br>"
  end


  get '/auth/:provider/callback' do
    result = request.env['omniauth.auth']
    erb "<a href='/'>Top</a><br>
         <h1>#{params[:provider]}</h1>
         <pre>#{JSON.pretty_generate(result)}</pre>"
  end
end

SinatraApp.run! if __FILE__ == $0
```

* トップページにTwitterログインへのリンク(`/auth/twitter`)を表示してやる
* `/auth/twitter`に飛ばすと、OmniAuthが勝手に認証処理を始めてくれる
  （[Integrating OmniAuth Into Your Application](https://github.com/intridea/omniauth#integrating-omniauth-into-your-application)）
* 認証が成功すると`/auth/twitter/callback`に飛んできて、`request.env['omniauth.auth']`に
  結果が入っているので、そこでユーザのTwitterアカウントの情報を取得できる
  * `request.env['omniauth.auth']['info']['nickname']`に名前、など
* 失敗した時は`/auth/failure`などに飛ばされる

### 他のウェブサービスでもログインできるようにする

OmniAuthではいろんなウェブサービスに対応できるようになっている（それぞれを`戦略`と呼ぶ）。
追加する手順は（例えば`github`用には）、

1. それぞれのウェブサービスで、認証を使うアプリを新規登録する（後述）
2. `Gemfile`に必要なgemファイルを追加する（`gem 'omniauth-github'`など）
  * `Gemfile`を更新したら`bundle install`を実行する
3. Rubyスクリプトから読み込む（`require 'omniauth-github'`）
4. `OmniAuth::Builder`に登録する（`provider :github, ENV['GITHUB_KEY'], ENV['GITHUB_SECRET']`）
  * ローカルテスト用に`export GITHUB_KEY='...'; export GITHUB_SECRET_KEY='...'`、
    herokuデプロイ用に`heroku config:add GITHUB_KEY=...`でそれぞれの環境変数に定義してやる

## ウェブサービスに認証アプリを登録
### github

* [Settings > Applications](https://github.com/settings/applications)で、
  「Register new application」でアプリを作成
* アプリ名、ホームページURL、アプリの説明などは適当に
* 「Authorization callback URL」には、ローカルテスト中は
  `http://localhost:4567/auth/github/callback`を指定する

### Facebook

* [Facebook Developers](https://developers.facebook.com/)から、
  [My Apps] > [+ Add a New App] > [ウェブサイト]でアプリを作成
  * 名前を適当に設定
  * ウェザードで順に設定する画面になるが、最上段の[My Apps]をクリックしてやるとアプリができている
* 作成したアプリを選んで、Settings > [+ Add Platform] > Website でアプリを登録する
  * `Site URL`と`Mobile Site URL`の２つが登録できるので、例えば１つはローカルテスト用に
    `http://localhost:4567/`を登録してやることもできる

### Google+

* [Google Developers Console](https://console.developers.google.com/project)で
  [プロジェクトを生成]で作成
* APIと認証 > 認証情報 > OAuth > 新しいクライアントIDを作成 で認証用のIDとシークレットキーを
  取得し、リダイレクトURLを登録できる
