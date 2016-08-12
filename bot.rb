#!/usr/bin/env ruby
#
#

require "./lib/greenbot.rb"
require 'mongo'
require 'awesome_print'

MONGO_URL = ENV['MONGO_URL'] || 'mongodb://127.0.0.1:27017/greenbot'


client = Mongo::Client.new(MONGO_URL)
Bots = client[:Bots]

pin = ask("To get started, please provide your PIN")
pin.upcase!

bot = Bots.find({passcode: pin.strip}).first 

if bot.nil?
  say("I'm sorry, I cannot find that bot.")
  return
end

ALPHA = "ABCDEFGHIJKLMNOP"


index = 0
bot['settings'].sort! {|x,y| x['name'] <=> y['name']}
bot['settings'].each do |s|
  s['menu_choice'] = ALPHA[index]
  index += 1
end

menu_choices = ''
bot['settings'].each do |s|
  menu_choices << s['menu_choice'] + ':' + s['name'] + " "
end
menu_choices << "Q:quit"

loop do
  choice = ask("Please pick the setting to change: #{menu_choices}")
  choice.strip!
  choice.upcase!
  break if choice == 'Q' 
  setting = bot['settings'].find  do |s| 
    s['menu_choice'].eql?(choice)
  end

  if setting.nil?
    say("I could not find that setting")
  else
    new_val = ask("The current value is: #{setting['value']}. Please send a single mesasge with the new value, or empty to keep.")
    new_val.strip!
    unless new_val.empty?
      Bots.update_one({"$and" => [{ "passcode" => pin.strip}, {"settings.name" => setting['name'] }]}, { '$set' =>  { "settings.$.value" => new_val }} )
    else
      say("Not updating value")
    end
  end
end 

say("Thank you. Session ended.")
