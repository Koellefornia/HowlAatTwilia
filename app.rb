require 'sinatra'
require 'uri'

# #setup RestClient caching backed by Memcachier
# RestClient.enable Rack::Cache,
#   :verbose      => true,
#   :metastore   => Dalli::Client.new,
#   :entitystore => Dalli::Client.new

def get_or_post(path, opts={}, &block)
  get(path, opts, &block)
  post(path, opts, &block)
end

get "/*" do
	# render web.md into the index tempate using erb
	markdown :web, :layout_engine => :erb, :layout => :index
end

# this route handles all POST requests from Twilio
post "/*" do

# take the body of the SMS and remove any spaces and make all lower case
incoming_sms = params["Body"].downcase

#If they text help return a help message
if incoming_sms.include?("help")
	# query Splitcast API and store JSON of spots
	response = Twilio::TwiML::Response.new  { |r| r.Sms "Search for a venue name and city to get a venue ID ie: \"The Warfield SF\". Once you have an ID, enter it to get the next 7 days of shows at that venue!" }
# if they send in just numbers search for a venue calendar
elsif incoming_sms.match('^[0-9]+$')
	
	response_string = ""

	data = RestClient.get("http://api.songkick.com/api/3.0/venues/#{incoming_sms}/calendar.json?apikey=PxY0ITiYDczYNR9t", :accept => :json)
	data = JSON.parse(data)
	
	if data["resultsPage"]["results"].empty?
	  response = Twilio::TwiML::Response.new  { |r| r.Sms "Sorry, no results for this venue ID" }
	else
	  data = data["resultsPage"]["results"]["event"]
	
	  data.each do |i|
	    unless i["start"]["datetime"].nil?
	      event_date = DateTime.parse(i["start"]["datetime"]).to_date
	      date_difference = event_date - DateTime.now.to_date
	       if date_difference > 0 && date_difference <= 7 
	        response_string << "#{i["displayName"]}\n"
	      end
	    end
	  end
	# build Twilio response
	  response = Twilio::TwiML::Response.new  { |r| r.Sms "Show Details: \n#{response_string}" }
	end


#otherwise interperate this search for a venue ID
else
	response_string = ""

	incoming_sms_escaped = URI.escape(incoming_sms)
	data = RestClient.get("http://api.songkick.com/api/3.0/search/venues.json?query=#{incoming_sms_escaped}&apikey=PxY0ITiYDczYNR9t", :accept => :json)
	data = JSON.parse(data)
	data = data["resultsPage"]["results"]["venue"]

	data.each { |i| response_string << "#{i["displayName"]}: #{i["id"]}\n" }

	response = Twilio::TwiML::Response.new  { |r| r.Sms "Venue and ID:\n#{response_string}" }
end
# return valid TwiML back to Twilio
response.text
end