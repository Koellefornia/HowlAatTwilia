require 'sinatra'
require 'uri'

#setup RestClient caching backed by Memcachier
RestClient.enable Rack::Cache,
:verbose      => true,
:metastore   => Dalli::Client.new,
:entitystore => Dalli::Client.new

def get_or_post(path, opts={}, &block)
	get(path, opts, &block)
	post(path, opts, &block)
end

get "/*" do
	# render web.md into the index	 tempate using erb
	markdown :web, :layout_engine => :erb, :layout => :index
end

# this route handles all POST requests from Twilio
post "/*" do

	# take the body of the SMS and remove any spaces and make all lower case
	incoming_sms = params["Body"].downcase

	#If they text help return a help message
	if incoming_sms.include?("help")
		response = Twilio::TwiML::Response.new  { |r| r.Sms "TODO: help text" }
	# else tke any input from the message and perform sentiment analysis
	else 
	

		# Call jamiembrown-tweet-sentiment-analysis test
		response = Unirest.get "https://jamiembrown-tweet-sentiment-analysis.p.mashape.com/api/?key=egeqgqgq1&text=I+love+Mashape",
		headers:{
			"X-Mashape-Key" => "WYEBGc4CCKmshOMt1uVwFNnkHpGCp1Zi1nijsnQLWCKx4OVnQ2",
			"Accept" => "application/json"
		}

		data=JSON.parse(data)

		# check if error 
		if data["error"]
			# retrieve the error message
			response = Twilio::TwiML::Response.new  { |r| r.Sms data["message"] }
		elsif data["sentiment"]
			# otherwise create sentiment feedback
			sentiment = data["sentiment"]
			score = data["score"]

			if(score <= -0.7)
				feedback = "TODO: very negative"
			elsif(score < 0.1)
				feedback = "TODO: negative"
			elsif(score >= 0.7)
		    feedback = "TODO: very positive"
		  elsif(score > 0.1)
		  	feedback = "TODO: positive"
			else
				feedback = "TODO: neutral"
			end

			# build Twilio response
			response = Twilio::TwiML::Response.new  { |r| r.Sms "Your sentiment analysis:\n#{feedback}" }
		end
	end
	# return valid TwiML back to Twilio
	response.text
end