require 'sinatra'
require "sinatra/reloader"
require 'aws-sdk'
require 'dotenv'

Dotenv.load

Aws.config.update({
        :region => 'us-east-1',
        :credentials => Aws::Credentials.new(ENV['AWS_KEY'],ENV['AWS_SECRET'])
})

face_collection = "making_collection"

s3 = Aws::S3::Resource.new(region:'us-east-1')
client = Aws::Rekognition::Client.new(region: 'us-east-1')

bucket_name = 'training.makingdevs.com'
the_bucket = s3.bucket(bucket_name)


get	'/' do

	@hello = 'Bienvenidos a Making Devs'

	if client.list_collections.collection_ids.include?(face_collection)
		p "The #{face_collection} already exist"
	else
		p "Creating #{face_collection} collection"
		client.create_collection({collection_id:face_collection})
	end

	erb :index
end

post '/upload' do

	image = params[:file][:tempfile]
	@filename = params[:file][:filename]
	@get_image = "http://#{bucket_name}.s3.amazonaws.com/#{@filename}"

	obj = the_bucket.object(@filename)
	obj.upload_file(image,acl:'public-read')

	erb :upload
end

post '/compare_faces' do
	@get_image = params[:get_image]
	fileroute = params[:filename]

	@matchFaces = []
	list = []

	the_bucket.objects(prefix: 'Directory/').each do |item|
	  list << item.key
	end
	list.delete_at(0)
	list.each do |image|
        resp = client.compare_faces({
          similarity_threshold: 60,
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
        if resp.face_matches.count > 0
                @matchFaces << image
        end
	end

	erb :compare_faces
end
