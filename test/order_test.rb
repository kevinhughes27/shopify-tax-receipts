require "test_helper"

class OrderTest < ActiveSupport::TestCase

  def app
    SinatraApp
  end

  setup do
    @shop = "apple.myshopify.com"
    @noop_shop = "banana.myshopify.com"
  end

  # possible using the app link
  test "order with products but no charity" do
    Charity.where(shop: @shop).destroy_all

    order_webhook = load_fixture 'order.json'
    SinatraApp.any_instance.expects(:verify_shopify_webhook).returns(true)
    Pony.expects(:mail).never
    post '/order.json', order_webhook, 'HTTP_X_SHOPIFY_SHOP_DOMAIN' => @shop
    assert last_response.ok?
  end

  test "order with no products" do
    order_webhook = load_fixture 'order.json'

    SinatraApp.any_instance.expects(:verify_shopify_webhook).returns(true)
    Pony.expects(:mail).never

    post '/order', order_webhook, 'HTTP_X_SHOPIFY_SHOP_DOMAIN' => @noop_shop
    assert last_response.ok?
  end

  test "order endpoint with products" do
    order_webhook = load_fixture 'order.json'

    SinatraApp.any_instance.expects(:verify_shopify_webhook).returns(true)
    fake "https://apple.myshopify.com/admin/shop.json", :body => load_fixture('shop.json')
    Pony.expects(:mail).once

    post '/order', order_webhook, 'HTTP_X_SHOPIFY_SHOP_DOMAIN' => @shop
    assert last_response.ok?
  end

  test "order with no email" do
    order_webhook = JSON.parse(load_fixture('order.json'))
    order_webhook['customer'].delete('email')
    order_webhook = order_webhook.to_json

    SinatraApp.any_instance.expects(:verify_shopify_webhook).returns(true)
    fake "https://apple.myshopify.com/admin/shop.json", :body => load_fixture('shop.json')

    Pony.expects(:mail).never

    post '/order', order_webhook, 'HTTP_X_SHOPIFY_SHOP_DOMAIN' => @shop
    assert last_response.ok?
  end

  test "order with no customer" do
    order_webhook = JSON.parse(load_fixture('order.json'))
    order_webhook.delete('customer')
    order_webhook = order_webhook.to_json

    SinatraApp.any_instance.expects(:verify_shopify_webhook).returns(true)
    fake "https://apple.myshopify.com/admin/shop.json", :body => load_fixture('shop.json')

    Pony.expects(:mail).never

    post '/order', order_webhook, 'HTTP_X_SHOPIFY_SHOP_DOMAIN' => @shop
    assert last_response.ok?
  end

  test "order endpoint with product percentage" do
    product = Product.find_by(shop: @shop)
    product.update_attribute(:percentage, 80)

    order_webhook = load_fixture 'order.json'

    SinatraApp.any_instance.expects(:verify_shopify_webhook).returns(true)
    fake "https://apple.myshopify.com/admin/shop.json", :body => load_fixture('shop.json')

    OrderWebhookJob.any_instance.expects(:render_pdf).with do |shop, charity, donation|
      assert_equal '477.60', donation.to_liquid['donation_amount']
    end

    Pony.expects(:mail).once

    post '/order', order_webhook, 'HTTP_X_SHOPIFY_SHOP_DOMAIN' => @shop
    assert last_response.ok?
  end

  test "charity with default email template" do
    charity = Charity.find_by(shop: @shop)
    charity.update_attribute(:email_template, nil)

    order_webhook = load_fixture 'order.json'

    SinatraApp.any_instance.expects(:verify_shopify_webhook).returns(true)
    fake "https://apple.myshopify.com/admin/shop.json", :body => load_fixture('shop.json')
    Pony.expects(:mail).with(has_entry(body: "Dear Bob Norman,\n\nOn behalf of Amnesty, we would like to thank you from the bottom of our hearts for your contribution to our cause. It may seem like a small gesture to you, but to us, it’s what we thrive on. Feel free to share the word to your friends and family as well!\n\nYou’ll find a copy of your tax receipt as an attachment in this email.\n\nAgain, thank you. We wouldn't be here without you.\n\nAmnesty\n"))

    post '/order', order_webhook, 'HTTP_X_SHOPIFY_SHOP_DOMAIN' => @shop
    assert last_response.ok?
  end

  test "charity with custom email template" do
    charity = Charity.find_by(shop: @shop)
    charity.update_attribute(:email_template, "liquid test {{ charity['name'] }}")

    order_webhook = load_fixture 'order.json'

    SinatraApp.any_instance.expects(:verify_shopify_webhook).returns(true)
    fake "https://apple.myshopify.com/admin/shop.json", :body => load_fixture('shop.json')
    Pony.expects(:mail).with(has_entry(body: "liquid test Amnesty"))

    post '/order', order_webhook, 'HTTP_X_SHOPIFY_SHOP_DOMAIN' => @shop
    assert last_response.ok?
  end

  test "charity with receipt_threshold above order value" do
    charity = Charity.find_by(shop: @shop)
    charity.update_attribute(:receipt_threshold, 600)

    order_webhook = load_fixture 'order.json'

    SinatraApp.any_instance.expects(:verify_shopify_webhook).returns(true)
    fake "https://apple.myshopify.com/admin/shop.json", :body => load_fixture('shop.json')

    Pony.expects(:mail).never

    post '/order', order_webhook, 'HTTP_X_SHOPIFY_SHOP_DOMAIN' => @shop
    assert last_response.ok?
  end

  private

  def session
    { shopify: {shop: @shop, token: 'token'} }
  end
end
