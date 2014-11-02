require "test_helper"
require "./lib/app"
require 'byebug'

class AppTest < ActiveSupport::TestCase

  def app
    SinatraApp
  end

  def setup
    @shop = "apple.myshopify.com"
    @noop_shop = "banana.myshopify.com"
  end

  def test_order_enpoint_with_no_products
    order_webhook = load_fixture 'order_webhook.json'

    SinatraApp.any_instance.expects(:verify_shopify_webhook).returns(true)
    Pony.expects(:mail).never

    post '/order.json', order_webhook, 'HTTP_X_SHOPIFY_SHOP_DOMAIN' => @noop_shop
    assert last_response.ok?
  end

  def test_order_enpoint_with_products
    order_webhook = load_fixture 'order_webhook.json'

    SinatraApp.any_instance.expects(:verify_shopify_webhook).returns(true)
    fake "https://apple.myshopify.com/admin/shop.json", :body => load_fixture('shop.json')
    Pony.expects(:mail).once

    post '/order.json', order_webhook, 'HTTP_X_SHOPIFY_SHOP_DOMAIN' => @shop
    assert last_response.ok?
  end

  def test_charity_with_default_email_template
    charity = Charity.find_by(shop: @shop)
    charity.update_attribute(:email_template, nil)

    order_webhook = load_fixture 'order_webhook.json'

    SinatraApp.any_instance.expects(:verify_shopify_webhook).returns(true)
    fake "https://apple.myshopify.com/admin/shop.json", :body => load_fixture('shop.json')
    Pony.expects(:mail).with(has_entry(body: "Dear Bob Norman,\n\nOn behalf of Amnesty, we would like to thank you from the bottom of our hearts for your contribution to our cause. It may seem like a small gesture to you, but to us, it’s what we thrive on. Feel free to share the word to your friends and family as well!\n\nYou’ll find a copy of your tax receipt as an attachment in this email.\n\nAgain, thank you. We wouldn’t be here without you.\n\nAmnesty\n"))

    post '/order.json', order_webhook, 'HTTP_X_SHOPIFY_SHOP_DOMAIN' => @shop
    assert last_response.ok?
  end

  def test_charity_with_custom_email_template
    charity = Charity.find_by(shop: @shop)
    charity.update_attribute(:email_template, "liquid test {{ charity['name'] }}")

    order_webhook = load_fixture 'order_webhook.json'

    SinatraApp.any_instance.expects(:verify_shopify_webhook).returns(true)
    fake "https://apple.myshopify.com/admin/shop.json", :body => load_fixture('shop.json')
    Pony.expects(:mail).with(has_entry(body: "liquid test Amnesty"))

    post '/order.json', order_webhook, 'HTTP_X_SHOPIFY_SHOP_DOMAIN' => @shop
    assert last_response.ok?
  end
end
