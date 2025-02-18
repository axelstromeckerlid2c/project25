require 'sinatra'
require 'slim'
require 'sqlite3'
require 'sinatra/reloader'
#require 'becrypt'

get('/') do
    slim(:main)
end

get('/create') do
    slim(:create)
end

get('/profile') do
    slim(:profile)
end