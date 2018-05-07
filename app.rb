require 'sinatra'
require "sinatra/reloader"
require 'aws-sdk'
require 'dotenv'

Dotenv.load

Aws.config.update({
        :region => 'us-east-1',
        :credentials => Aws::Credentials.new(ENV['AWS_KEY'],ENV['AWS_SECRET'])
})

get	'/' do
	@hello = 'Bienvenidos a making devs'
	erb :index
end

post '/upload' do
	s3 = Aws::S3::Resource.new(region:'us-east-1')

	@image = params[:file][:tempfile]
	@filename = params[:file][:filename]
	@route = "Directory/#{@filename}"
	bucket = 'training.makingdevs.com'

	obj = s3.bucket(bucket).object(@route)
	obj.upload_file(@image)

	erb :upload
end
