require 'sinatra'
require 'slim'
require 'sqlite3'
require 'sinatra/reloader'
#require 'becrypt'

get('/') do
    slim(:main)
end