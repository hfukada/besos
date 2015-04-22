require 'cinch'
require 'json'
require './player.rb'


# For reasons unknown to me @instance variables don't work when you use helpers so that's cool i guess... 

$config = JSON.parse(File.read('config.json'))
$what = "WHAT"
$players = {}
$taboo = {}
$words = File.read('words.txt').split "\n"
$penalty = $config['penalty'] || 3

class Besos
  def initialize()

    @bot = Cinch::Bot.new do
      configure do |c|
        c.server = $config['server']
        c.ssl.use = true
        c.messages_per_second = 10
        c.port = $config['port']
        c.nick = $config['nick']
        c.user = $config['user']
        c.password = $config['password']
        c.channels = $config['rooms']
      end

      helpers do
        def release_word(name)
          $words.push($taboo.select{|w,p| p[:name] == name}.first)
        end

        def rand_word()
          $words.delete_at rand($words.size)
        end

        def rand_target(name)
          t = $players.keys.sample
          until t != name do
            t = $players.keys.sample
          end
          t
        end

        def assign_target(name)
          t_word = rand_word
          target=rand_target(name)
          $taboo[t_word] = {reward:name, target:target}
          {target:target, t_word:t_word}
        end

        def reward_player(player)
          $players[player][:score] += 5
          release_word player
          t=assign_target player
          player.send "you did it m80! now go make #{t[:target]} say: #{t[:t_word]}"
        end

        def swap_target(player)
          release_word player
          $players[player][:score] -= $penalty
          t=assign_target player
          "you didn't do it. You failure. go make #{t[:target]} say: #{t[:t_word]}"
        end

        def add_player(name)
          $players[name] = {name: name, score: 0}
          t=assign_target name
          "You have joined.
          make #{t[:target]} say: #{t[:t_word]}"
        end

        def remove_player(name)
          release_word(name)
          $players.delete name
          "You have been removed."
        end

        def print_help()
          "Welcome to Besos. An assasins style chat game. Once you join, you will get a mission. Your mission is to get your target to say a specific word. When your target says that word, you will be rewarded with their bounty. Default it 3 points.
            Available commands:
            !help: displays this message
            !join: add yourself to the game
            !quit: remove yourself from the game
            !score: prints the leaderboard
            !giveup: give up on your current mission, get another at a penalty of #{$penalty} points"
        end

        def print_scoreboard()
          $players.values.sort_by{|p| p[:score]}.reverse.map{|p| "#{p[:name]} #{p[:score]}"}.join "\n"
        end

        def process(sender, message)
          message.split.each{|w| if $taboo[w] and $taboo[w][:target] == sender then reward_player $taboo[w][:reward] end}
        end
      end

      on :message, /.*/ do |m|
        puts "User: #{m.user}"
        puts "Text: #{m.message}"
        process(m.user, m.message)
      end

      on :message, /^!join$/ do |m, who, text|
        puts "User #{m.user} wants to play"
        m.user.send add_player(m.user)
      end

      on :message, /^!giveup$/ do |m|
        m.user.send swap_target(m.user)
      end

      on :message, /^!quit$/ do |m, who, text|
        m.user.send remove_player(m.user)
      end

      on :message, /^!score$/ do |m|
        m.user.send print_scoreboard()
      end

      on :message, /^!gamehelp$/ do |m|
        m.reply print_help()
      end
    end
    def run()
      puts "starting besos."
      @bot.start
    end
  end

end

Besos.new.run
