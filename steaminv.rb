require 'httparty'
require 'json'
require 'pp'
require 'twitter'

@CONFIG = YAML.load_file File.expand_path '../config_deezinking.yml', __FILE__
$INVCONF = YAML.load_file File.expand_path '../steaminv_config.yml', __FILE__
OpenSSL::SSL::VERIFY_PEER = OpenSSL::SSL::VERIFY_NONE

@Twitter = Twitter::REST::Client.new do |config|
  config.consumer_key    		= @CONFIG[:twitter_key]
  config.consumer_secret 		= @CONFIG[:twitter_secret]
  config.access_token        	= @CONFIG[:twitter_token]
  config.access_token_secret 	= @CONFIG[:twitter_token_secret]
end

puts "[#{Time.new.strftime("%d-%m-%Y %H:%M:%S")}] Twitter logged in"
@Twitter.update("[#{Time.new.strftime("%d-%m-%Y %H:%M:%S")}] Hello. Who am I? CS:GO Drop Helper v1.11")

#arraydef
$response = Array.new($INVCONF[:number_of_accounts].to_i)
$responsetemp = Array.new($INVCONF[:number_of_accounts].to_i)
$count1 = Array.new($INVCONF[:number_of_accounts].to_i)
$count2 = Array.new($INVCONF[:number_of_accounts].to_i)

#functions
def dropparse (database)
	parse = JSON.load([ database ].to_json).first
	firstid = parse["rgInventory"].first.first
	desc_id = parse["rgInventory"][firstid]["classid"] + '_' + parse["rgInventory"][firstid]["instanceid"]
	$drop = parse["rgDescriptions"][desc_id]["market_hash_name"]
end

def tweet (person, accnumber)
	@Twitter.update("[#{Time.new.strftime("%H:%M:%S")}] Yo @#{person}! Ein Drop auf dem #{accnumber}. Acc! #{$drop}")
end

def httpgetcheck(i)
	begin
	$responsetemp[i] = HTTParty.get("http://steamcommunity.com/profiles/#{$INVCONF[eval(':id' + i.to_s)]}/inventory/json/730/2")
	rescue => e				#fucking steam servers...
	retry while true
	end
	
	if $responsetemp[i]["rgInventory"] != nil then
	$response[i] = $responsetemp[i]
	else
	puts "re-get #{$INVCONF[eval(":twitter#{i.to_s}")]} #{$INVCONF[eval(":accnr#{i.to_s}")]}"
	httpgetcheck(i)
	end
end

def httpget
	for i in 1..$INVCONF[:number_of_accounts].to_i
	httpgetcheck(i)
	puts "got #{$INVCONF[eval(":twitter#{i.to_s}")]} #{$INVCONF[eval(":accnr#{i.to_s}")]}"
	end
end

def count(arr)
	for i in 1..$INVCONF[:number_of_accounts].to_i
		if $response[i]["rgInventory"] != nil then
		arr[i] = $response[i]["rgInventory"].count
		puts "counted #{$INVCONF[eval(":twitter#{i.to_s}")]} #{$INVCONF[eval(":accnr#{i.to_s}")]}: #{arr[i]}"
		end
	end
end

#Var-Predef
httpget
count($count2)

#Mainloop
while 1!=2 do
puts "[#{Time.new.strftime("%d-%m-%Y %H:%M:%S")}] Looped"
sleep(60)
httpget
count($count1)
	for i in 1..$INVCONF[:number_of_accounts].to_i
		if $count1[i] > $count2[i]
		dropparse($response[i])
		tweet($INVCONF[eval(":twitter#{i.to_s}")],$INVCONF[eval(":accnr#{i.to_s}")])
		$count2[i] = $count1[i]
		end

		if $count1[i] < $count2[i]
		$count2[i] = $count1[i]
		end
	end
end