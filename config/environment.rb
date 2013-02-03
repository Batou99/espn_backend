require 'bundler'

env = ENV['RACK_ENV'] || 'development'
Bundler.require :default, env

require 'logger'
require 'active_resource'

$stdout.sync = true
logger = Logger.new($stdout)

ActiveResource::Base.logger = logger

require './app'
