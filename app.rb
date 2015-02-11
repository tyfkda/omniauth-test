require 'rubygems'
require 'sinatra'
require 'sinatra/reloader' if development?
require 'json'
require 'omniauth'
require 'omniauth-github'

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
  end

  get '/' do
    erb "<% if session[:authenticated] %>
           <div>
             Hello, <b><%= session[:nickname] %></b>!
           </div>
           <a href='/logout'>Logout</a><br>
         <% else %>
           <a href='/auth/github'>Login with Github</a><br>
         <% end %>"
  end

  get '/auth/:provider/callback' do
    result = request.env['omniauth.auth']
    session[:authenticated] = true
    session[:provider] = result['provider']
    session[:uid] = result['uid']
    session[:nickname] = result['info']['nickname']
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
