ENV['RACK_ENV'] = 'test'
ENV['SHOPIFY_REDIRECT_URI'] = 'http://localhost:4567'
ENV['SECRET'] = 'secret'
ENV['DEVELOPMENT'] = '1'

require 'minitest/autorun'
require 'active_support/test_case'
require 'rack/test'
require 'mocha/setup'
require 'fakeweb'
require 'byebug'

require "./lib/app"

FakeWeb.allow_net_connect = false

module Helpers
  include Rack::Test::Methods

  def init_db
    apple = Shop.create!(name: 'apple.myshopify.com', token: 'token')
    Charity.create!(shop: apple.name, name: 'Amnesty', charity_id: 12345)
    Product.create(shop: apple.name, product_id: 632910392)

    banana = Shop.create!(name: 'banana.myshopify.com', token: 'token')
    Charity.create(shop: banana.name, name: 'Amnesty', charity_id: 56789)
  end

  def reset_db
    Charity.delete_all
    Product.delete_all
  end

  def load_fixture(name)
    File.read("./test/fixtures/#{name}")
  end

  def fake(url, options={})
    method = options.delete(:method) || :get
    body = options.delete(:body) || '{}'
    format = options.delete(:format) || :json

    FakeWeb.register_uri(method, url, {:body => body, :status => 200, :content_type => "application/#{format}"}.merge(options))
  end

  def activate_shopify_session(shop, token)
    session = ShopifyAPI::Session.new(shop, token)
    ShopifyAPI::Base.activate_session session
  end
end

class Minitest::Test
  include Helpers

  def setup
    init_db
  end

  def teardown
    reset_db
  end
end
