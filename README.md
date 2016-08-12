# owner-settings-bot

This bot allows an outsider to change the settings for a particular bot.  When each bot is created,
a unique passcode is also created to identify it.  This passcode is used for this bot. 

# Annotated Source

Setup for ruby, shebang and library requires

```
#!/usr/bin/env ruby
#
#
require "./lib/greenbot.rb"
require 'mongo'
require 'awesome_print'
```

The bot works directly on the database. A mongo installed on the localhost and named greenbot is the default.

```
MONGO_URL = ENV['MONGO_URL'] || 'mongodb://127.0.0.1:27017/greenbot'
```

Open up the Bots collection in the database, go grab the local bots.

```
client = Mongo::Client.new(MONGO_URL)
Bots = client[:Bots]
```

Authenticate the inbound texter with the passcode, and use that
to get the right bot to work with.

```
pin = ask("To get started, please provide your PIN")
pin.upcase!

bot = Bots.find({passcode: pin.strip}).first 

if bot.nil?
  say("I'm sorry, I cannot find that bot.")
  return
end
```

To make it easier for the texter, use a single letter to identify the settings to update.
We add a sequential letter to the existing record set. We don't persist that in the database.

```
ALPHA = "ABCDEFGHIJKLMNOP"
index = 0
bot['settings'].sort! {|x,y| x['name'] <=> y['name']}
bot['settings'].each do |s|
  s['menu_choice'] = ALPHA[index]
  index += 1
end
```

Prepare the list of choices to present to the texter.

```
menu_choices = ''
bot['settings'].each do |s|
  menu_choices << s['menu_choice'] + ':' + s['name'] + " "
end
menu_choices << "Q:quit"
```

The main loop. We keep looping until somebody says Q.
As the loop goes, collect the choice from the user.
Then, display the current value, and offer a chance to
update it.  Keep that up until done.

```
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
    Bots.update_one({"$and" => [{ "passcode" => pin.strip}, {"settings.name" => setting['name'] }]}, { '$set' =>  { "settings.$.value" => new_val }} )
  end
end 
```

And... we're done.

```
say("Thank you. Session ended.")
```
