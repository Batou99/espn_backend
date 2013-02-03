require 'active_resource'
require "net/http"

env = ENV['RACK_ENV'] || 'development'
config = YAML::load( File.open( 'config/connection.yml' ) )[env]
API_KEY = config["api_key"]
ESPN_SERVER = config["espn_server"]
API_VERSION = config["api_version"]

class Leagues < Array
  def self.from_json(data)
    leagues = Leagues.new
    parsed_data = JSON.parse(data)
    jleagues = parsed_data["sports"][0]["leagues"]
    jleagues.each { |league|  
      l = League.from_json(league)
      leagues << l
      # Try not to query too fast so we don't do more than 3 req/seq
      # In a real time scenario this data would be prefetched on start
      # and cached
      sleep(1)
    }
    leagues
  end

  # In real life we would load data in parts instead of chaining everything 
  # from here
  def self.load(retries=3)
    raise "Impossible to load data, try again later" if retries<1
    begin
      api_params = "apikey=#{API_KEY}"
      http = Net::HTTP.new(ESPN_SERVER)
      request = Net::HTTP::Get.new("/#{API_VERSION}/sports/basketball/teams/?#{api_params}")
      Leagues.from_json(http.request(request).body)
    rescue
      load(retries-1)
    end
  end
end

class League
  attr_accessor :name
  attr_accessor :id
  attr_accessor :abbr
  attr_accessor :teams

  def initialize
    @teams = []
  end

  def self.from_json(data)
    league = League.new
    league.name = data["name"]
    league.abbr = data["abbreviation"]
    league.id = data["id"]
    league.load_teams
    league
  end

  def load_teams
    api_params = "apikey=#{API_KEY}"
    http = Net::HTTP.new(ESPN_SERVER)
    request = Net::HTTP::Get.new("/#{API_VERSION}/sports/basketball/#{@abbr}/teams/?#{api_params}")
    response = http.request(request).body
    parsed_response = JSON.parse(response)
    parsed_response["sports"][0]["leagues"][0]["teams"].each { |team|
      @teams << Team.from_json(team)
    }
  end
end

class Team
  attr_accessor :name
  attr_accessor :id
  attr_accessor :abbr
  attr_accessor :color
  attr_accessor :location
  attr_accessor :headlines_url

  def self.from_json(data)
    team = Team.new
    team.name = data["name"]
    team.id = data["id"]
    team.abbr = data["abbreviation"]
    team.color = data["color"]
    team.location = data["location"]
    team.headlines_url = data["links"]["api"]["news"]["href"]
    team
  end
end

class Headline
  attr_accessor :link_text
  attr_accessor :description
  attr_accessor :image

  def self.create(data)
    headline = Headline.new
    headline.link_text = data["linkText"]
    headline.description = data["description"]
    begin
      headline.image = data["images"][0]["url"]
    rescue
    end
    headline
  end
end

class Headlines < Array
  def self.load(league,team_id,limit)
    http = Net::HTTP.new(ESPN_SERVER)
    api_params = "limit=#{limit}&apikey=#{API_KEY}"
    request = Net::HTTP::Get.new("/#{API_VERSION}/sports/basketball/#{league}/teams/#{team_id}/news/?#{api_params}")
    response = http.request(request).body
    parsed_response = JSON.parse(response)
    headlines = Headlines.new
    parsed_response["headlines"].each { |headline|  
      headlines << Headline.create(headline)
    }
    headlines
  end
end
