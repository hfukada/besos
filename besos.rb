require 'cinch'
require 'json'
require './player.rb'

class Besos
  def initialize()
    @config = JSON.parse(File.read('config.json'))
    @players = {}
    @words = File.read('words.txt').split "\n"
    @penalty = @config['penalty']
    @bot = nil
  end

  def run()
    puts "starting besos."
    @bot = Cinch::Bot.new do
      configure do |c|
        c.server = @config['server']
        c.ssl.use = true
        c.port = @config['port']
        c.nick = @config['nick']
        c.user = @config['user']
        c.password = @config['password']
        c.channels = @config['rooms']
      end

      on :message, /^!play$/ do |sender,to,message|
        sender.reply add_player(sender)
      end

      on :message, /^!giveup$/ do |sender,to,message|
        sender.reply swap_target(sender)
      end

      on :message, /^!quit$/ do |sender,to,message|
        sender.reply remove_player(sender)
      end

      on :message, /^!score$/ do |sender,to,message|
        sender.reply print_scoreboard(sender)
      end

      on :message, /^!gamehelp$/ do |sender,to,message|
        sender.reply print_help(sender)
      end
    end
    @bot.start
  end

  def add_player(name)
    @players[name] = Player.new(name)
    "You have joined"
  end

  def remove_player
  end

  def print_help()
    "Welcome to Besos. An assasins style chat game. Once you join, you will get a mission. Your mission is to get your target to say a specific word. When your target says that word, you will be rewarded with their bounty. Default it 3 points.
      Available commands:
      !help: displays this message
      !join: add yourself to the game
      !quit: remove yourself from the game
      !score: prints the leaderboard
      !giveup: give up on your current mission, get another at a penalty of #{penalty} points"
  end

  def print_scoreboard(sender)
    players.map{|player|

    }
  end
end


Besos.new.run

#bot = Cinch::Bot.new do
#  configure do |c|
#    c.server = "fl.irc.slack.com"
#    c.ssl.use = true
#    c.port = 6697
#    c.nick = "besos"
#    c.user = "besos"
#    c.password = "fl.h1tVhxq0xK25603XHftl"
#    c.channels = ["#bot_testing"]
#  end
#
#  on :message, /[gG][oO][nN][gG][! .]?/ do |m|
#    `/usr/bin/aplay /home/hiroshi/random/gongongong.wav`
#  end
#end
#
#bot.start
#
#
