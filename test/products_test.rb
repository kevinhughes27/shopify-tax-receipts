require "test_helper"

class ProductsTest < ActiveSupport::TestCase
  def app
    SinatraApp
  end

  setup do
    @shop = "apple.myshopify.com"
  end

  test "products admin link / product picker" do
    fake "https://apple.myshopify.com/admin/shop.json", :body => load_fixture('shop.json')
    fake "https://apple.myshopify.com/admin/products/1.json", :body => load_fixture('product.json')
    fake "https://apple.myshopify.com/admin/products/2.json", :body => load_fixture('product.json')

    assert_difference 'Product.count', +2 do
      get '/products', {ids: [1,2]}, 'rack.session' => session
      assert last_response.redirect?
    end
  end

  test "product admin link" do
    fake "https://apple.myshopify.com/admin/shop.json", :body => load_fixture('shop.json')
    fake "https://apple.myshopify.com/admin/products/1.json", :body => load_fixture('product.json')

    assert_difference 'Product.count', +1 do
      get '/product', {id: 1}, 'rack.session' => session
      assert last_response.redirect?
    end
  end

  private

  def session
    { shopify: {shop: @shop, token: 'token'} }
  end
end
