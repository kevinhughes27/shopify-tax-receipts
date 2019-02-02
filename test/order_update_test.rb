require "test_helper"

class OrderUpdateTest < ActiveSupport::TestCase

  def app
    SinatraApp
  end

  setup do
    @shop = "apple.myshopify.com"
  end

  test "order update no change" do
    order_webhook = load_fixture 'order.json'
    order = JSON.parse(order_webhook)

    Donation.create!(
      shop: @shop,
      order: order.to_json,
      order_id: order['id'],
      order_number: order['name'],
      donation_amount: 597.00,
      created_at: 5.days.ago,
    )

    SinatraApp.any_instance.expects(:verify_shopify_webhook).returns(true)
    fake "https://apple.myshopify.com/admin/shop.json", :body => load_fixture('shop.json')
    Pony.expects(:mail).never

    assert_no_difference 'Donation.count' do
      post '/order', order_webhook, 'HTTP_X_SHOPIFY_SHOP_DOMAIN' => @shop
      assert last_response.ok?
    end
  end

  test "order update with name change" do
    order_webhook = load_fixture 'order.json'
    order = JSON.parse(order_webhook)

    original_donation = Donation.create!(
      shop: @shop,
      order: order.to_json,
      order_id: order['id'],
      order_number: order['name'],
      donation_amount: 597.00
    )

    order['billing_address']['first_name'] = 'Robert'
    order_webhook = order.to_json

    SinatraApp.any_instance.expects(:verify_shopify_webhook).returns(true)
    fake "https://apple.myshopify.com/admin/shop.json", :body => load_fixture('shop.json')
    OrderWebhookJob.any_instance.expects(:notify_pdf_change)
    Pony.expects(:mail).once

    assert_difference 'Donation.count', +1 do
      post '/order', order_webhook, 'HTTP_X_SHOPIFY_SHOP_DOMAIN' => @shop
      assert last_response.ok?
    end

    assert original_donation.reload.void
    new_donation = Donation.last
    assert_equal 'update', new_donation.status
  end

  test "order update with email change" do
    order_webhook = load_fixture 'order.json'
    order = JSON.parse(order_webhook)

    original_donation = Donation.create!(
      shop: @shop,
      order: order.to_json,
      order_id: order['id'],
      order_number: order['name'],
      donation_amount: 597.00
    )

    order['email'] = 'robert.norman@hostmail.com'
    order_webhook = order.to_json

    SinatraApp.any_instance.expects(:verify_shopify_webhook).returns(true)
    fake "https://apple.myshopify.com/admin/shop.json", :body => load_fixture('shop.json')
    Pony.expects(:mail).once

    assert_difference 'Donation.count', +1 do
      post '/order', order_webhook, 'HTTP_X_SHOPIFY_SHOP_DOMAIN' => @shop
      assert last_response.ok?
    end

    assert original_donation.reload.void
    new_donation = Donation.last
    assert_equal 'update', new_donation.status
  end

  test "existing donation is update" do
    order_webhook = load_fixture 'order.json'
    order = JSON.parse(order_webhook)

    Donation.create!(
      status: 'void',
      shop: @shop,
      order: order.to_json,
      order_id: order['id'],
      order_number: order['name'],
      donation_amount: 597.00,
    )

    update_donation = Donation.create!(
      status: 'update',
      shop: @shop,
      order: order.to_json,
      order_id: order['id'],
      order_number: order['name'],
      donation_amount: 597.00,
    )

    # no change
    SinatraApp.any_instance.expects(:verify_shopify_webhook).returns(true)
    fake "https://apple.myshopify.com/admin/shop.json", :body => load_fixture('shop.json')
    Pony.expects(:mail).never

    assert_no_difference 'Donation.count' do
      post '/order', order_webhook, 'HTTP_X_SHOPIFY_SHOP_DOMAIN' => @shop
      assert last_response.ok?
    end

    # name change
    order['billing_address']['first_name'] = 'Robert'
    order_webhook = order.to_json

    SinatraApp.any_instance.expects(:verify_shopify_webhook).returns(true)
    fake "https://apple.myshopify.com/admin/shop.json", :body => load_fixture('shop.json')
    OrderWebhookJob.any_instance.expects(:notify_pdf_change)
    Pony.expects(:mail).once

    assert_difference 'Donation.count', +1 do
      post '/order', order_webhook, 'HTTP_X_SHOPIFY_SHOP_DOMAIN' => @shop
      assert last_response.ok?
    end

    assert update_donation.reload.void
    new_donation = Donation.last
    assert_equal 'update', new_donation.status
  end

  test "existing donation is void" do
    order_webhook = load_fixture 'order.json'
    order = JSON.parse(order_webhook)

    Donation.create!(
      status: 'void',
      shop: @shop,
      order: order.to_json,
      order_id: order['id'],
      order_number: order['name'],
      donation_amount: 597.00,
    )

    SinatraApp.any_instance.expects(:verify_shopify_webhook).returns(true)
    fake "https://apple.myshopify.com/admin/shop.json", :body => load_fixture('shop.json')
    Pony.expects(:mail).never

    assert_no_difference 'Donation.count' do
      post '/order', order_webhook, 'HTTP_X_SHOPIFY_SHOP_DOMAIN' => @shop
      assert last_response.ok?
    end
  end

  test "existing donation is thresholded no change" do
    order_webhook = load_fixture 'order.json'
    order = JSON.parse(order_webhook)

    Donation.create!(
      status: 'thresholded',
      shop: @shop,
      order: order.to_json,
      order_id: order['id'],
      order_number: order['name'],
      donation_amount: 597.00,
    )

    SinatraApp.any_instance.expects(:verify_shopify_webhook).returns(true)
    fake "https://apple.myshopify.com/admin/shop.json", :body => load_fixture('shop.json')
    Pony.expects(:mail).never

    assert_no_difference 'Donation.count' do
      post '/order', order_webhook, 'HTTP_X_SHOPIFY_SHOP_DOMAIN' => @shop
      assert last_response.ok?
    end
  end

  test "existing donation is thresholded, updated dontation not thresholded with email change" do
    order_webhook = load_fixture 'order.json'
    order = JSON.parse(order_webhook)

    original_donation = Donation.create!(
      status: 'thresholded',
      shop: @shop,
      order: order.to_json,
      order_id: order['id'],
      order_number: order['name'],
      donation_amount: 597.00
    )

    order['email'] = 'robert.norman@hostmail.com'
    order_webhook = order.to_json

    SinatraApp.any_instance.expects(:verify_shopify_webhook).returns(true)
    fake "https://apple.myshopify.com/admin/shop.json", :body => load_fixture('shop.json')
    Pony.expects(:mail).once

    assert_difference 'Donation.count', +1 do
      post '/order', order_webhook, 'HTTP_X_SHOPIFY_SHOP_DOMAIN' => @shop
      assert last_response.ok?
    end

    assert original_donation.reload.void
    new_donation = Donation.last
    assert_nil new_donation.status
  end

  test "existing donation is thresholded, updated dontation thresholded with email change" do
    charity = Charity.find_by(shop: @shop)
    charity.update_attribute(:receipt_threshold, 1000)

    order_webhook = load_fixture 'order.json'
    order = JSON.parse(order_webhook)

    original_donation = Donation.create!(
      status: 'thresholded',
      shop: @shop,
      order: order.to_json,
      order_id: order['id'],
      order_number: order['name'],
      donation_amount: 597.00
    )

    order['email'] = 'robert.norman@hostmail.com'
    order_webhook = order.to_json

    SinatraApp.any_instance.expects(:verify_shopify_webhook).returns(true)
    fake "https://apple.myshopify.com/admin/shop.json", :body => load_fixture('shop.json')
    Pony.expects(:mail).never

    assert_difference 'Donation.count', +1 do
      post '/order', order_webhook, 'HTTP_X_SHOPIFY_SHOP_DOMAIN' => @shop
      assert last_response.ok?
    end

    assert original_donation.reload.void
    new_donation = Donation.last
    assert new_donation.thresholded
  end

  test "existing donation not thresholded, updated dontation thresholded with email change" do
    charity = Charity.find_by(shop: @shop)
    charity.update_attribute(:receipt_threshold, 1000)

    order_webhook = load_fixture 'order.json'
    order = JSON.parse(order_webhook)

    original_donation = Donation.create!(
      shop: @shop,
      order: order.to_json,
      order_id: order['id'],
      order_number: order['name'],
      donation_amount: 597.00
    )

    order['email'] = 'robert.norman@hostmail.com'
    order_webhook = order.to_json

    SinatraApp.any_instance.expects(:verify_shopify_webhook).returns(true)
    fake "https://apple.myshopify.com/admin/shop.json", :body => load_fixture('shop.json')
    Pony.expects(:mail).once

    assert_difference 'Donation.count', +1 do
      post '/order', order_webhook, 'HTTP_X_SHOPIFY_SHOP_DOMAIN' => @shop
      assert last_response.ok?
    end

    assert original_donation.reload.void
    new_donation = Donation.last
    assert_equal 'update', new_donation.status
  end
end
