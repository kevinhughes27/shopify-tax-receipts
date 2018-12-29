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
    fake "https://apple.myshopify.com/admin/shop.json", :body => load_fixture('shop.json')
    Pony.expects(:mail).once

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
    fake "https://apple.myshopify.com/admin/shop.json", :body => load_fixture('shop.json')
    Pony.expects(:mail).once

    assert_difference 'Donation.count', +1 do
      post '/order', order_webhook, 'HTTP_X_SHOPIFY_SHOP_DOMAIN' => @shop
      assert last_response.ok?
    end

    original_donation = Donation.last
    refund_webhook = load_fixture 'order_partial_refund.json'

    SinatraApp.any_instance.expects(:verify_shopify_webhook).returns(true)
    fake "https://apple.myshopify.com/admin/shop.json", :body => load_fixture('shop.json')
    Pony.expects(:mail).once

    assert_difference 'Donation.count', +1 do
      post '/order', refund_webhook, 'HTTP_X_SHOPIFY_SHOP_DOMAIN' => @shop
      assert last_response.ok?
      new_donation = Donation.last
      assert_equal new_donation.status, 'update'
      assert original_donation.reload.void
    end
  end
end
