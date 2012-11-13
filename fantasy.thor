require 'nokogiri'
require 'open-uri'
require 'yaml'
require 'hirb'

class Fantasy < Thor

  PLAYOFF_MATCHUPS_URL  = 'http://espn.go.com/nba/playoffs/matchups'

  REMAINING_GAMES_URL   = PLAYOFF_MATCHUPS_URL

  # # # # # # #

  desc 'remaining_games', 'Display remaining games for NBA teams'

  method_option :file, :aliases => '-f', :lazy_default => 'remaining.txt', :desc => "Output list to FILE (Default: ./remaining.txt)"
  method_option :sort, :aliases => '-s', :default => 'remaining', :desc => "Possible sort values: remaining, home, away"

  def remaining_games
    tell "Downloading remaining games information..."

    doc = load_doc(REMAINING_GAMES_URL)
    teams = doc.css('#my-teams-table .span-2').xpath('//tr[contains(@class, "team-")]')

    data = []
    teams.each do |team|
      info = team.css('td')[1]
      name = info.css('strong > a').first.content
      games_match = info.content.match /(\d+)\s\((\d+)[^0-9]*(\d+).*\)/
      data << {
        :name => name,
        :remaining => games_match[1],
        :home => games_match[2],
        :away => games_match[3]
      }
    end

    table = hirb_table(data, options[:sort].to_sym)

    if file = options[:file]
      File.open(File.join(Dir.pwd, file), 'w') { |f| f.write(table.to_s) }
    else
      puts table
    end
  end

  private

    def tell(msg, overwrite=false)
      if overwrite
        print msg + " " * 20 + "\r"
        $stdout.flush
      else
        $stdout.puts msg
      end
    end

    def load_doc(url)
      Nokogiri::HTML(open(url))
    end

    def hirb_table(data, sort)
      data.sort_by! { |d| d[sort] }.reverse!

      Hirb::Helpers::AutoTable.render(data,
        :number => true, 
        :fields => data[0].keys
      )
    end
end