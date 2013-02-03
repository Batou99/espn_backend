require 'bundler'

env = ENV['RACK_ENV'] || 'development'
Bundler.require :default, env

require 'logger'

$stdout.sync = true
logger = Logger.new($stdout)

require './app'
