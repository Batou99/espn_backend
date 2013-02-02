require 'bundler'

env = ENV['RACK_ENV'] || 'development'
Bundler.require :default, env

require './app'
