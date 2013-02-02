require "net/http"

module ESPN
  env = ENV['RACK_ENV'] || 'development'
  config = YAML::load( File.open( 'config/connection.yml' ) )[env]
  API_KEY = config["api_key"]
  ESPN_SERVER = config["espn_server"]
  API_VERSION = config["api_version"]

  class Connector < Grape::API

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

    options 'headline' do end

    desc "Retrieve info from ESPN"
    params do
      requires :league_name, :type => String, :desc => "League Name"
      optional :limit, :type => Integer, :desc => "Max # of entries"
      optional :offset, :type => Integer, :desc => "Offset # of entries"
    end
    get '/sports/basketball/:league_name/news' do
      params[:limit] ||= 5
      params[:offset] ||= 0
      http = Net::HTTP.new(ESPN::ESPN_SERVER)
      api_params = "limit=#{params[:limit]}&offset=#{params[:offset]}&apikey=#{ESPN::API_KEY}"
      puts api_params
      puts "/#{ESPN::API_VERSION}/sports/basketball/#{params[:league_name]}/news#{api_params}"
      request = Net::HTTP::Get.new("/#{ESPN::API_VERSION}/sports/basketball/#{params[:league_name]}/news?#{api_params}")
      present http.request(request).body
    end

  end
end
