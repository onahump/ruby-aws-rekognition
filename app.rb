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

	list =[]
	names = []

	if client.list_faces({ collection_id: face_collection, max_results: 20, }).faces.size == 0
		the_bucket.objects(prefix: 'Directory/').each do |item|
		  	list << item.key
		end
		list.delete_at(0)

		list.each do |letter|
			letter = letter.sub(/(Directory\W)/,'')
			letter =letter.sub(/(\Wjpg|\Wjpeg|\Wpng)/,'')
			names << letter
		end	

		list.zip(names).each do |list,names|
			client.index_faces({
		      collection_id: face_collection,
		      detection_attributes: [
		      ],
		      external_image_id: names,
		      image: {
		        s3_object: {
		          bucket: bucket_name,
		          name: list,
		        },
		      },
		    })
		end
	else
		p "Already exist faces"
	end

	p client.list_faces({ collection_id: face_collection, max_results: 20, }).faces.size
	
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
	
	directory = []	
	the_bucket.objects(prefix: 'Directory/').each do |item|
		  	directory << item.key
		end
	directory.delete_at(0)
	

	resp = client.search_faces_by_image({
	  collection_id: face_collection, 
	  face_match_threshold: 95, 
	  image: {
	    s3_object: {
	      bucket: bucket_name, 
	      name: fileroute, 
	    }, 
	  }, 
	  max_faces: 5, 
	})

	match = resp.face_matches
	names_match = []
	
	if match.size >= 1
		match.each do |image|
			names_match << image.face.external_image_id
		end
	end

	directory.each do |dir|
		aux = dir.clone
		aux = aux.sub!(/(Directory\W)/,"")
		aux = aux.sub!(/(\Wjpg|\Wjpeg|\Wpng)/,"")
		names_match.each do |name|
			if aux == name
				@matchFaces << dir
			end
		end
	end

	erb :compare_faces
end
