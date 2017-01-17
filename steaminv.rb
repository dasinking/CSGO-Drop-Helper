# -*- encoding : utf-8 -*-
require 'httparty'
require 'json'
require 'pp'
require 'twitter'
require 'uri'

@CONFIG = YAML.load_file File.expand_path '../config_deezinking.yml', __FILE__
$INVCONF = YAML.load_file File.expand_path '../steaminv_config.yml', __FILE__
OpenSSL::SSL::VERIFY_PEER = OpenSSL::SSL::VERIFY_NONE

@Twitter = Twitter::REST::Client.new do |config|
  config.consumer_key    		= @CONFIG[:twitter_key]
  config.consumer_secret 		= @CONFIG[:twitter_secret]
  config.access_token        	= @CONFIG[:twitter_token]
  config.access_token_secret 	= @CONFIG[:twitter_token_secret]
end

@Twitter.update("[#{Time.new.strftime("%d-%m-%Y %H:%M:%S")}] CS:GO Drop Helper v3 online")
puts "[#{Time.new.strftime("%d-%m-%Y %H:%M:%S")}] CS:GO Drop Helper v3 online"

$response     = Array.new($INVCONF[:number_of_accounts].to_i)
$responsetemp = Array.new($INVCONF[:number_of_accounts].to_i)
$count1       = Array.new($INVCONF[:number_of_accounts].to_i)
$count2       = Array.new($INVCONF[:number_of_accounts].to_i)

#functions
def pricecheck (markethash)
	priceget = HTTParty.get(URI.encode("http://steamcommunity.com/market/priceoverview/?currency=3&appid=730&market_hash_name=#{markethash}"))
	if priceget["success"] == true then 
    $price = "(#{priceget["lowest_price"]})"
  else
    $price = ""
  end
end

def dropparse (i)
  parse   = JSON.load([ $response[i] ].to_json).first
  classid = parse["assets"].first["classid"]

  #classid-suche
    for x in 0..parse["descriptions"].count  
      if parse["descriptions"][x]["classid"] == classid then
        begin
          classid = x
          break
        end
      end
    end

  if parse["descriptions"][classid]["market_hash_name"].include? "Souvenir" then
    $drop = "#{parse["descriptions"][classid]["market_hash_name"]} signed by #{parse["descriptions"][classid]["tags"].last["internal_name"].split.first}"
    pricecheck(parse["descriptions"][classid]["market_hash_name"])
    tweet(i)
    else
      if $INVCONF[eval(":major#{i.to_s}")] == "0" then
        $drop = parse["descriptions"][classid]["market_hash_name"]
        pricecheck(parse["descriptions"][classid]["market_hash_name"])
        tweet(i)
      else
        $drop = ""
        $price = ""
      end
    end
end

def tweet (i)
  		@Twitter.update("[#{Time.new.strftime("%H:%M:%S")}] Yo @#{$INVCONF[eval(":twitter#{i.to_s}")]} @ #{$INVCONF[eval(":accnr#{i.to_s}")]}. Acc! hf with your #{$drop}! #{$price}")
  				   puts "[#{Time.new.strftime("%H:%M:%S")}] Yo @#{$INVCONF[eval(":twitter#{i.to_s}")]} @ #{$INVCONF[eval(":accnr#{i.to_s}")]}. Acc! hf with your #{$drop}! #{$price}"
end

def http
  for i in 1..$INVCONF[:number_of_accounts].to_i
    while 1!=2
      httpget(i)
      break if httpgetcheck(i) == true
      sleep(3)
    end
    puts "got #{$INVCONF[eval(":twitter#{i.to_s}")]} #{$INVCONF[eval(":accnr#{i.to_s}")]}"
  end
end

def httpget(i)
  $responsetemp[i] = HTTParty.get("http://steamcommunity.com/inventory/#{$INVCONF[eval(':id' + i.to_s)]}/730/2?l=english&count=5000")
  rescue => e       #fucking steam servers...
  retry while true
end

def httpgetcheck(i)
  if $responsetemp[i]["assets"] != nil then
    $response[i] = $responsetemp[i]
    return true
  else
    puts "re-get #{$INVCONF[eval(":twitter#{i.to_s}")]} #{$INVCONF[eval(":accnr#{i.to_s}")]}"
    return false
  end
end

def count(arr)
  for i in 1..$INVCONF[:number_of_accounts].to_i
    if $response[i]["assets"] != nil then
      arr[i] = $response[i]["assets"].count
      puts "counted #{$INVCONF[eval(":twitter#{i.to_s}")]} #{$INVCONF[eval(":accnr#{i.to_s}")]}: #{arr[i]}"
    end
  end
end

http                    #first definition of the inventories
count($count2)

while 1!=2 do           #main loop
  puts "[#{Time.new.strftime("%d-%m-%Y %H:%M:%S")}] Looped"
  sleep(15)
  http
  count($count1)
  for i in 1..$INVCONF[:number_of_accounts].to_i
    if $count1[i] > $count2[i]
      dropparse(i)
      $count2[i] = $count1[i]
    end
    if $count1[i] < $count2[i]
      $count2[i] = $count1[i]
    end
  end
end