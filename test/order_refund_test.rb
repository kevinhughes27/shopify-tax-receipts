require "test_helper"

class OrderRefundTest < ActiveSupport::TestCase

  def app
    SinatraApp
  end

  setup do
    @shop = "apple.myshopify.com"
  end

  test "full refund sends void receipt" do
    order_webhook = load_fixture 'order.json'
    order = JSON.parse(order_webhook)

    donation = Donation.create!(
      shop: @shop,
      order: order.to_json,
      order_id: order['id'],
      order_number: order['name'],
      donation_amount: 597.00
    )

    order['financial_status'] = 'refunded'
    order_webhook = order.to_json

    SinatraApp.any_instance.expects(:verify_shopify_webhook).returns(true)
    mock_shop_api_call
    Pony.expects(:mail).once

    assert_no_difference 'Donation.count' do
      post '/order', order_webhook, 'HTTP_X_SHOPIFY_SHOP_DOMAIN' => @shop
      assert last_response.ok?
      assert donation.reload.void
    end
  end

  test "full refund doesn't email if already void" do
    order_webhook = load_fixture 'order.json'
    order = JSON.parse(order_webhook)

    donation = Donation.create!(
      shop: @shop,
      order: order.to_json,
      order_id: order['id'],
      order_number: order['name'],
      donation_amount: 597.00,
      status: 'void'
    )

    order['financial_status'] = 'refunded'
    order_webhook = order.to_json

    SinatraApp.any_instance.expects(:verify_shopify_webhook).returns(true)
    mock_shop_api_call
    Pony.expects(:mail).never

    assert_no_difference 'Donation.count' do
      post '/order', order_webhook, 'HTTP_X_SHOPIFY_SHOP_DOMAIN' => @shop
      assert last_response.ok?
      assert donation.reload.void
    end
  end

  test "refund of thresholded voids donation but does not email" do
    order_webhook = load_fixture 'order.json'
    order = JSON.parse(order_webhook)

    donation = Donation.create!(
      shop: @shop,
      status: 'thresholded',
      order: order.to_json,
      order_id: order['id'],
      order_number: order['name'],
      donation_amount: 597.00
    )

    order['financial_status'] = 'refunded'
    order_webhook = order.to_json

    SinatraApp.any_instance.expects(:verify_shopify_webhook).returns(true)
    mock_shop_api_call
    Pony.expects(:mail).never

    assert_no_difference 'Donation.count' do
      post '/order', order_webhook, 'HTTP_X_SHOPIFY_SHOP_DOMAIN' => @shop
      assert last_response.ok?
      assert donation.reload.void
    end
  end

  test "partial refund" do
    Product.create(shop: @shop, product_id: 2757640645)

    order_webhook = load_fixture 'order_before_refund.json'

    SinatraApp.any_instance.expects(:verify_shopify_webhook).returns(true)
    mock_shop_api_call
    Pony.expects(:mail).once

    assert_difference 'Donation.count', +1 do
      post '/order', order_webhook, 'HTTP_X_SHOPIFY_SHOP_DOMAIN' => @shop
      assert last_response.ok?
    end

    original_donation = Donation.last
    assert_equal 398.0, original_donation.donation_amount
    refund_webhook = load_fixture 'order_partial_refund.json'

    SinatraApp.any_instance.expects(:verify_shopify_webhook).returns(true)
    mock_shop_api_call
    Pony.expects(:mail).once

    assert_difference 'Donation.count', +1 do
      post '/order', refund_webhook, 'HTTP_X_SHOPIFY_SHOP_DOMAIN' => @shop
      assert last_response.ok?
      new_donation = Donation.last
      assert_equal 'update', new_donation.status
      assert_equal 199.0, new_donation.donation_amount
      assert original_donation.reload.void
    end
  end

  test "partial refund of thresholded order updates donation but does not email" do
    charity = Charity.find_by(shop: @shop)
    charity.update_attribute(:receipt_threshold, 1000)

    Product.create(shop: @shop, product_id: 2757640645)

    order_webhook = load_fixture 'order_before_refund.json'

    SinatraApp.any_instance.expects(:verify_shopify_webhook).returns(true)
    mock_shop_api_call
    Pony.expects(:mail).never

    assert_difference 'Donation.count', +1 do
      post '/order', order_webhook, 'HTTP_X_SHOPIFY_SHOP_DOMAIN' => @shop
      assert last_response.ok?
    end

    original_donation = Donation.last
    assert original_donation.thresholded

    refund_webhook = load_fixture 'order_partial_refund.json'

    SinatraApp.any_instance.expects(:verify_shopify_webhook).returns(true)
    mock_shop_api_call
    Pony.expects(:mail).never

    assert_difference 'Donation.count', +1 do
      post '/order', refund_webhook, 'HTTP_X_SHOPIFY_SHOP_DOMAIN' => @shop
      assert last_response.ok?
      new_donation = Donation.last
      assert_equal 'thresholded', new_donation.status
      assert original_donation.reload.void
    end
  end

  test "multiple partial refund" do
    Product.create(shop: @shop, product_id: 2757640645)

    order_webhook = load_fixture 'order_before_refund.json'

    SinatraApp.any_instance.expects(:verify_shopify_webhook).returns(true)
    mock_shop_api_call
    Pony.expects(:mail).once

    assert_difference 'Donation.count', +1 do
      post '/order', order_webhook, 'HTTP_X_SHOPIFY_SHOP_DOMAIN' => @shop
      assert last_response.ok?
    end

    original_donation = Donation.last
    assert_equal 398.0, original_donation.donation_amount
    refund_webhook = load_fixture 'order_partial_refund.json'

    SinatraApp.any_instance.expects(:verify_shopify_webhook).returns(true)
    mock_shop_api_call
    Pony.expects(:mail).once

    assert_difference 'Donation.count', +1 do
      post '/order', refund_webhook, 'HTTP_X_SHOPIFY_SHOP_DOMAIN' => @shop
      assert last_response.ok?
      new_donation = Donation.last
      assert_equal 'update', new_donation.status
      assert_equal 199.0, new_donation.donation_amount
      assert original_donation.reload.void
    end

    second_donation = Donation.last

    second_refund_webhook = JSON.parse(load_fixture('order_partial_refund.json'))
    refund = second_refund_webhook["refunds"][0]
    second_refund_webhook["refunds"].push(refund)
    second_refund_webhook = second_refund_webhook.to_json

    SinatraApp.any_instance.expects(:verify_shopify_webhook).returns(true)
    mock_shop_api_call
    Pony.expects(:mail).once

    assert_difference 'Donation.count', +1 do
      post '/order', second_refund_webhook, 'HTTP_X_SHOPIFY_SHOP_DOMAIN' => @shop
      assert last_response.ok?
      new_donation = Donation.last
      assert_equal 'update', new_donation.status
      assert_equal 0.0, new_donation.donation_amount
      assert second_donation.reload.void
    end
  end
end
