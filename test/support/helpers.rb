module Helpers
  include Rack::Test::Methods

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
