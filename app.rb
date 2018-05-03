require 'sinatra'
require "sinatra/reloader"
require 'aws-sdk'

get	'/' do 
	erb :index
end


