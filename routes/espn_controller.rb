require "net/http"
require_relative "../models/models"

module ESPN
  env = ENV['RACK_ENV'] || 'development'
  config = YAML::load( File.open( 'config/connection.yml' ) )[env]
  API_KEY = config["api_key"]
  ESPN_SERVER = config["espn_server"]
  API_VERSION = config["api_version"]
  puts "Preloading leagues data..."
  LEAGUES ||= Leagues.load # Preload Leagues data on start

  class Connector < Grape::API

    version 'v1', :using => :path # This is our API version, not ESPN's

    format :json
    before do
      # FIXME: Change this to support only connections from the frontend
      header "Access-Control-Allow-Origin", "*"
      header "Access-Control-Allow-Methods", "POST, GET, PUT, DELETE, OPTIONS"
      header "Access-Control-Allow-Headers", "X-Requested-With,If-Modified-Since,Cache-Control,Content-Type"
    end

    helpers do
    end

    module Entities
      class Headline < Grape::Entity
      end
    end

    options '/sports/basketball/leagues_and_teams' do end
    desc "Retrieve info from ESPN: Leagues and teams names"
    params do
    end
    get '/sports/basketball/leagues_and_teams' do
      # We cache the results because the teams won't change much
      # In a real scenario, we would use something like memechache
      # with expires
      present LEAGUES.to_json
    end


    options '/sports/basketball/:league_name/teams/:id/news' do end
    desc "Retrieve info from ESPN: News from a team"
    params do
      requires :league_name, :type => String, :desc => "League Name"
      requires :id, :type => Integer, :desc => "Team id"
      optional :limit, :type => Integer, :desc => "Max # of entries"
    end
    get '/sports/basketball/:league_name/teams/:id/news' do
      params[:league_name] ||= 'nba'
      params[:limit] ||= 5
      present Headlines.load(params[:league_name],params[:id],params[:limit]).to_json
    end
  end
end
