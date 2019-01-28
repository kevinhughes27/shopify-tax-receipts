$VERBOSE = nil

ENV['RACK_ENV'] = 'test'
ENV['SECRET'] = 'secret'
ENV['DEVELOPMENT'] = '1'

require 'minitest/autorun'
require 'active_support/test_case'
require 'rack/test'

require 'database_cleaner'
require 'sidekiq/testing'
require 'pdf/inspector'
require 'mocha/setup'
require 'fakeweb'
require 'json'

require_relative './support/helpers'
require_relative './support/seed'

require './src/app'

Sidekiq::Testing.inline!

FakeWeb.allow_net_connect = false

DatabaseCleaner.strategy = :transaction

seed_db

class ActiveSupport::TestCase
  include Helpers

  setup do
    DatabaseCleaner.start
  end

  teardown do
    FakeWeb.clean_registry
    DatabaseCleaner.clean
  end
end
