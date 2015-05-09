require 'sinatra'
require 'uri'
require 'unirest'
# require 'rest-client'

#setup RestClient caching backed by Memcachier
# RestClient.enable Rack::Cache,
#  :verbose      => true,
#  :metastore   => Dalli::Client.new,
#  :entitystore => Dalli::Client.new

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
	puts "-----------------------------------INCOMING TEXT --------------------------------------------"
	puts incoming_sms
	puts "---------------------------------------------------------------------------------------------"
	#If they text help return a help message
	if incoming_sms.include?("help")
		response = Twilio::TwiML::Response.new  { |r| r.Sms "Welcome to Ask Twilia! Twilia lends you a neutral set of eyes to find out whats in that his last sms. In order to get her opnion of his sms, just forward his sms to Twilias phone." }
	# else tke any input from the message and perform sentiment analysis
	else 
	

		# Call jamiembrown-tweet-sentiment-analysis test
		text = incoming_sms.delete(",.!?").gsub(" ", "+")
		puts "-----------------------------------TEXT TO ANALYZE ------------------------------------------"
		puts text
		puts "---------------------------------------------------------------------------------------------"
		# Call jamiembrown-tweet-sentiment-analysis test
		response = Unirest.get("https://jamiembrown-tweet-sentiment-analysis.p.mashape.com/api/?key=WYEBGc4CCKmshOMt1uVwFNnkHpGCp1Zi1nijsnQLWCKx4OVnQ2&text=#{text}", 
								headers: {
									"X-Mashape-Key" => "WYEBGc4CCKmshOMt1uVwFNnkHpGCp1Zi1nijsnQLWCKx4OVnQ2",
									"Accept" => "application/json"
								})
	
		# puts response	
		data=JSON.parse(response)

		# check if error 
		if data["error"]
			# retrieve the error message
			response = Twilio::TwiML::Response.new  { |r| r.Sms data["message"] }
		elsif data["sentiment"]
			# otherwise create sentiment feedback
			sentiment = data["sentiment"]
			score = data["score"]

			if(score <= -0.7)
				feedback = "Oh dear! That doesnt look good. I think he is just not that into you. Might be time for strategic withdrawal?"
			elsif(score < 0.1)
				feedback = "This is not very convincing or affectionate. Maybe another insight will help. Forward me another of his sms."
			elsif(score >= 0.7)
		    feedback = "Jackpot! Looks like someone has a good day and wants to share it with you! Gwan girl, you got this!"
		  elsif(score > 0.1)
		  	feedback = "I think he likes you. Is he just sweet or is there more. Lets see another of his sms!"
			else
				feedback = "\"If you're not in the game, you can't hit a home run.\" might be a bad Hoff quote, but are you in the game or not? I cant read too much into this. Can I please see another sms?"
			end

			# build Twilio response
			response = Twilio::TwiML::Response.new  { |r| r.Sms "Your sentiment analysis:\n#{feedback}" }
		end
	end
	# return valid TwiML back to Twilio
	response.text
end