require 'cinch'
require 'json'

# For reasons unknown to me @instance variables don't work when you use helpers so that's cool i guess...

$config = JSON.parse(File.read('config.json'))
$owner=$config['owner']
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
        def restore_state()
          $players = JSON.parse(File.read('players.json'))
          $taboo = JSON.parse(File.read('taboo.json'))
          $words = JSON.parse(File.read('words.json'))
        end

        def save_state()
          File.open("players.json","w") do |f|
              f.write($players.to_json())
          end
          File.open("words.json","w") do |f|
              f.write($words.to_json())
          end
          File.open("taboo.json","w") do |f|
              f.write($taboo.to_json())
          end
        end

        def release_word(name)
          puts "return #{$taboo.select{|w,p| puts p
                             p["reward"] == name}}"
          $words.push($taboo.select{|w,p| p["reward"] == name}.first.first)
          $taboo.delete($taboo.select{|w,p| p["reward"] == name}.first.first)
          puts "final: #{$words}"
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
          target=rand_target name
          $taboo[t_word] = {"reward" => name, "target" => target}
          {"target" => target, "t_word" => t_word}
        end

        def reward_player(player, dead, word)
          $players[player]["score"] += 5
          release_word player
          t=assign_target player
          User(dead).send "You find yourself in a dark alley. Suddenly you feel a swift blow to the back of your neck. You wake up in a mud puddle. You can't remember much but you find a damp note that reads \"you've been hit by #{player} for saying #{word}\""
          User(player).send "Congratulations, you've successfully accomplished your mission. You've given #{player} the swift hit for saying #{word}. I'll be awarding you accordingly. Good work...
Your new target is sure to be found in the #general channel. This fellow goes by the name of #{t["target"]}. I need you to cough up the word '#{t["t_word"]}'. I know you can do it. Don't let me down"
        end

        def swap_target(player)
          release_word player
          $players[player]["score"] -= $penalty
          t=assign_target player
          "I see. Well, if you can't handle it, you can't handle it. Fortunately for you, an Assassin's work is never done. I'll give you a new mission... but it's going to cost you a mark.  Ahh, I found something in the deep in the books. Your mission is now to coerce #{t["target"]} into saying: '#{t["t_word"]}'"
        end

        def remind(player)
          w = $taboo.select{|w,p| p["reward"] == player}.first
          "Your mission is to make #{w[1]["target"]} say '#{w.first}'. If you can't, I could probably find you some new work if you type !giveup but it'll cost you a few marks. I hope you don't have to resort to !giveup. I'm counting on you."
          end

        def add_player(name)
          if $players[name].nil?
            puts "User #{m.user} wants to play"
            $players[name] = {"name"=> name, "score" => 0}
            t=assign_target name
            puts $words
            "You have joined. Welcome to the Slack Mafia of the Farmlouge District. I have a mission for you: I need you to slyly make #{t["target"]} say '#{t["t_word"]}' using any means neccessary. Good luck."
          end
        end

        def remove_player(name)
          release_word name
          $players.delete name
          "You have been removed."
        end

        def print_help()
          "Welcome to Besos. An assasins style chat game. Once you join, you will get a mission. Your mission is to get your target to say a specific word. When your target says that word, you will be rewarded with their bounty. Default it 3 points.
Available commands:
!besos: displays this message
!join: add yourself to the game
!quit: remove yourself from the game
!score: prints the leaderboard
!remind: reminds you what your mission is.
!giveup: give up on your current mission, get another at a penalty of #{$penalty} points
Note: in this game version you cannot die. you simply are rewarded or penalized points. Game goes on until this bot dies or botmaster turns this off"
        end

        def print_scoreboard()
          $players.values.sort_by{|p| p["score"]}.reverse.map{|p| "#{p["name"]} #{p["score"]}"}.join "\n"
        end

        def process(sender, message)
          message.split.each{|w| if $taboo[w] and $taboo[w]["target"] == sender then reward_player $taboo[w]["reward"], sender, w end}
        end
      end

      on :message, /.*/ do |m|
        process(m.user.nick, m.message)
      end

      on :message, /^!adminrestore$/ do |m|
        if m.user.nick == $owner
          restore_state
          m.user.send "State restored"
        end
      end

      on :message, /^!adminsave$/ do |m|
        if m.user.nick == $owner
          save_state
          m.user.send "State saved"
        end
      end

      on :message, /^!join$/ do |m, who, text|
        m.user.send add_player(m.user.nick)
      end

      on :message, /^!remind$/ do |m|
        m.user.send remind(m.user.nick)
      end

      on :message, /^!giveup$/ do |m|
        m.user.send swap_target(m.user.nick)
      end

      on :message, /^!quit$/ do |m, who, text|
        m.user.send remove_player(m.user.nick)
      end

      on :message, /^!score$/ do |m|
        m.user.send print_scoreboard()
      end

      on :message, /^!besos$/ do |m|
        m.user.send print_help()
      end
    end

    def run()
      puts "starting besos."
      @bot.start
    end
  end

end

Besos.new.run
