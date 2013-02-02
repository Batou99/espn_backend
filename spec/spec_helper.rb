require 'rubygems'
require 'factory_girl'
require 'rack/test'
require 'json_spec'
require 'database_cleaner'
require 'bundler/setup'

ENV['RACK_ENV'] = 'test'

require File.join(File.dirname(__FILE__), '..', 'config', 'environment')

FactoryGirl.find_definitions

RSpec.configure do |config|
  config.include Rack::Test::Methods
  config.include JsonSpec::Helpers
  config.include Mongoid::Matchers

  def app
    Calx
  end
 
  config.before(:suite) do
    DatabaseCleaner.strategy = :truncation
    DatabaseCleaner.clean_with(:truncation)
  end

  config.before(:each) do
    DatabaseCleaner.start
  end

  config.after(:each) do
    DatabaseCleaner.clean
  end
end
