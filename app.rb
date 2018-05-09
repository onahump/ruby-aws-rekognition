require 'sinatra'
require "sinatra/reloader"
require 'aws-sdk'
require 'dotenv'

Dotenv.load

Aws.config.update({
        :region => 'us-east-1',
        :credentials => Aws::Credentials.new(ENV['AWS_KEY'],ENV['AWS_SECRET'])
})

s3 = Aws::S3::Resource.new(region:'us-east-1')
client = Aws::Rekognition::Client.new(region: 'us-east-1')
bucket_name = 'your-bucket-name'
the_bucket = s3.bucket(bucket_name)


get	'/' do
	@hello = 'Bienvenidos a Making Devs'
	erb :index
end

post '/upload' do

	@image = params[:file][:tempfile]	
	@filename = params[:file][:filename]
	@route = "Directory/#{@filename}"

	obj = the_bucket.object(@route)
	obj.upload_file(@image)
	obj.get(response_target: "public/images/#{@filename}")

	erb :upload
end

post '/compare_faces' do
	fileroute = params[:filename]

	lista = []
	the_bucket.objects(prefix: 'Directory/').each do |item|
	  lista << item.key
	end
	lista.delete_at(0)

	lista.each do |image|
			resp = client.compare_faces({
			  similarity_threshold: 90, 
			  source_image: {
			    s3_object: {
			      bucket: "#{bucket_name}", 
			      name: "#{fileroute}", 
			    }, 
			  }, 
			  target_image: {
			    s3_object: {
		 		  bucket: "#{bucket_name}", 
			      name: "#{image}"
			    }, 
			  }, 
			})

			if resp.face_matches.count >= 1
				p "Match"
			else
				p "UnMatch"
			end
	end

end