require "test_helper"

class AppTest < ActiveSupport::TestCase

  def app
    SinatraApp
  end

  setup do
    @shop = "apple.myshopify.com"
    @noop_shop = "banana.myshopify.com"
  end

  test "get_install" do
    get '/install'
    assert last_response.ok?
  end

  test "order_endpoint_with_no_products" do
    order_webhook = load_fixture 'order_webhook.json'

    SinatraApp.any_instance.expects(:verify_shopify_webhook).returns(true)
    Pony.expects(:mail).never

    post '/order.json', order_webhook, 'HTTP_X_SHOPIFY_SHOP_DOMAIN' => @noop_shop
    assert last_response.ok?
  end

  test "order_endpoint_with_products" do
    order_webhook = load_fixture 'order_webhook.json'

    SinatraApp.any_instance.expects(:verify_shopify_webhook).returns(true)
    fake "https://apple.myshopify.com/admin/shop.json", :body => load_fixture('shop.json')
    Pony.expects(:mail).once

    post '/order.json', order_webhook, 'HTTP_X_SHOPIFY_SHOP_DOMAIN' => @shop
    assert last_response.ok?
  end

  test "order_endpoint_with_product_percentage" do
    product = Product.find_by(shop: @shop)
    product.update_attribute(:percentage, 80)

    order_webhook = load_fixture 'order_webhook.json'

    SinatraApp.any_instance.expects(:verify_shopify_webhook).returns(true)
    fake "https://apple.myshopify.com/admin/shop.json", :body => load_fixture('shop.json')

    SinatraApp.any_instance.expects(:render_pdf).with do |shop, order, charity, donation_amount|
      assert_equal '477.60', donation_amount
    end

    Pony.expects(:mail).once

    post '/order.json', order_webhook, 'HTTP_X_SHOPIFY_SHOP_DOMAIN' => @shop
    assert last_response.ok?
  end

  test "charity_with_default_email_template" do
    charity = Charity.find_by(shop: @shop)
    charity.update_attribute(:email_template, nil)

    order_webhook = load_fixture 'order_webhook.json'

    SinatraApp.any_instance.expects(:verify_shopify_webhook).returns(true)
    fake "https://apple.myshopify.com/admin/shop.json", :body => load_fixture('shop.json')
    Pony.expects(:mail).with(has_entry(body: "Dear Bob Norman,\n\nOn behalf of Amnesty, we would like to thank you from the bottom of our hearts for your contribution to our cause. It may seem like a small gesture to you, but to us, it’s what we thrive on. Feel free to share the word to your friends and family as well!\n\nYou’ll find a copy of your tax receipt as an attachment in this email.\n\nAgain, thank you. We wouldn’t be here without you.\n\nAmnesty\n"))

    post '/order.json', order_webhook, 'HTTP_X_SHOPIFY_SHOP_DOMAIN' => @shop
    assert last_response.ok?
  end

  test "charity_with_custom_email_template" do
    charity = Charity.find_by(shop: @shop)
    charity.update_attribute(:email_template, "liquid test {{ charity['name'] }}")

    order_webhook = load_fixture 'order_webhook.json'

    SinatraApp.any_instance.expects(:verify_shopify_webhook).returns(true)
    fake "https://apple.myshopify.com/admin/shop.json", :body => load_fixture('shop.json')
    Pony.expects(:mail).with(has_entry(body: "liquid test Amnesty"))

    post '/order.json', order_webhook, 'HTTP_X_SHOPIFY_SHOP_DOMAIN' => @shop
    assert last_response.ok?
  end

  test "resend" do
    order_id = 1234
    donation = Donation.create!(shop: @shop, order_id: order_id, donation_amount: 10)

    fake "https://apple.myshopify.com/admin/orders/#{order_id}.json", :body => load_fixture('order_webhook.json')
    fake "https://apple.myshopify.com/admin/shop.json", :body => load_fixture('shop.json')

    Pony.expects(:mail).once

    params = {id: donation.id}
    post '/resend', params, 'rack.session' => session

    assert last_response.redirect?
    assert_equal 'Email resent!', last_request.env['x-rack.flash'][:notice]
  end

  test "test_email" do
    charity = Charity.find_by(shop: @shop)
    charity.update_attribute(:email_template, nil)

    fake "https://apple.myshopify.com/admin/shop.json", :body => load_fixture('shop.json')
    Pony.expects(:mail).with(has_entry(body: "Dear Bob Norman,\n\nOn behalf of Amnesty, we would like to thank you from the bottom of our hearts for your contribution to our cause. It may seem like a small gesture to you, but to us, it’s what we thrive on. Feel free to share the word to your friends and family as well!\n\nYou’ll find a copy of your tax receipt as an attachment in this email.\n\nAgain, thank you. We wouldn’t be here without you.\n\nAmnesty\n"))

    get '/test_email', {}, 'rack.session' => session
    assert last_response.ok?
  end

  private

  def session
    { shopify: {shop: @shop, token: 'token'} }
  end
end
