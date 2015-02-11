require 'rubygems'
require 'sinatra'
require 'sinatra/reloader' if development?
require 'json'
require 'omniauth'
require 'omniauth-github'
require 'omniauth-twitter'
require 'omniauth-facebook'
require 'omniauth-gplus'

class SinatraApp < Sinatra::Base
  configure :development do
    register Sinatra::Reloader
  end

  configure do
    set :sessions, true
    set :inline_templates, true
  end

  use OmniAuth::Builder do
    provider :github, ENV['GITHUB_KEY'], ENV['GITHUB_SECRET']
    provider :twitter, ENV['TWITTER_KEY'], ENV['TWITTER_SECRET']
    provider :facebook, ENV['FACEBOOK_KEY'], ENV['FACEBOOK_SECRET']
    provider :gplus, ENV['GPLUS_KEY'], ENV['GPLUS_SECRET'], scope: 'plus.login'
  end

  get '/' do
    erb "<% if session[:authenticated] %>
           <div>
             Hello, <b><%= session[:nickname] %></b>! [<%= session[:provider] %>]
           </div>
           <a href='/logout'>Logout</a><br>
         <% else %>
           <a href='/auth/github'>Login with Github</a><br>
           <a href='/auth/twitter'>Login with Twitter</a><br>
           <a href='/auth/facebook'>Login with Facebook</a><br>
           <a href='/auth/gplus'>Login with Google+</a><br>
         <% end %>"
  end

  get '/auth/:provider/callback' do
    result = request.env['omniauth.auth']
    session[:authenticated] = true
    session[:provider] = result['provider']
    session[:uid] = result['uid']
    session[:nickname] = result['info']['nickname'] || result['info']['first_name']
    erb "<a href='/'>Top</a><br>
         <h1>#{params[:provider]}</h1>
         <pre>#{JSON.pretty_generate(result)}</pre>"
  end

  get '/auth/failure' do
    erb "<h1>Authentication Failed:</h1><h3>message:<h3> <pre>#{params}</pre>"
  end

  get '/auth/:provider/deauthorized' do
    erb "#{params[:provider]} has deauthorized this app."
  end

  get '/protected' do
    throw(:halt, [401, "Not authorized\n"]) unless session[:authenticated]
    erb "<pre>#{request.env['omniauth.auth'].to_json}</pre><hr>
         <a href='/logout'>Logout</a>"
  end

  get '/logout' do
    session[:authenticated] = false
    redirect '/'
  end
end

SinatraApp.run! if __FILE__ == $0
