module Helpers
  include Rack::Test::Methods

  def activate_shopify_session(shop, token)
    session = ShopifyAPI::Session.new(domain: shop, token: token, api_version: '2019-04')
    ShopifyAPI::Base.activate_session session
  end

  def mock_shop_api_call
    fake "https://apple.myshopify.com/admin/api/2019-04/shop.json", :body => load_fixture('shop.json')
  end

  def mock_order_api_call(order_id)
    fake "https://apple.myshopify.com/admin/api/2019-04/orders/#{order_id}.json", :body => load_fixture('order.json')
  end

  def mock_product_api_call(product_id)
    fake "https://apple.myshopify.com/admin/api/2019-04/products/#{product_id}.json", :body => load_fixture('product.json')
  end

  def fake(url, options={})
    method = options.delete(:method) || :get
    body = options.delete(:body) || '{}'
    format = options.delete(:format) || :json

    FakeWeb.register_uri(method, url, {:body => body, :status => 200, :content_type => "application/#{format}"}.merge(options))
  end

  def load_fixture(name)
    File.read("./test/fixtures/#{name}")
  end
end
