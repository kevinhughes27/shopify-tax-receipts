require "test_helper"
require "./lib/app"
require 'byebug'
class AppTest < Minitest::Test

  def app
    SinatraApp
  end

  def setup
    @shop_name = "apple.myshopify.com"
  end

  def test_order_enpoint_with_no_products
    order_webhook = load_fixture 'order_webhook.json'

    SinatraApp.any_instance.expects(:verify_shopify_webhook).returns(true)
    Pony.expects(:mail).never

    post '/order.json', order_webhook, 'HTTP_X_SHOPIFY_SHOP_DOMAIN' => @shop_name
    assert last_response.ok?
  end

  def test_order_enpoint_with_products
    product = Product.create!(shop: @shop_name, product_id: 632910392)
    order_webhook = load_fixture 'order_webhook.json'

    SinatraApp.any_instance.expects(:verify_shopify_webhook).returns(true)
    fake "https://apple.myshopify.com/admin/shop.json", :body => load_fixture('shop.json')
    Pony.expects(:mail).once

    post '/order.json', order_webhook, 'HTTP_X_SHOPIFY_SHOP_DOMAIN' => @shop_name
    assert last_response.ok?

    product.destroy
  end
end
