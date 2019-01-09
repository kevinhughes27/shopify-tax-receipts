require "test_helper"

class DonationTest < ActiveSupport::TestCase
  setup do
    @shop = "apple.myshopify.com"
  end

  test "only one non void donation per order is allowed" do
    assert Donation.create(shop: @shop, order_id: 1234, donation_amount: 10, status: 'void').persisted?
    assert Donation.create(shop: @shop, order_id: 1234, donation_amount: 10, status: 'void').persisted?
    assert Donation.create(shop: @shop, order_id: 1234, donation_amount: 10, status: nil).persisted?
    refute Donation.create(shop: @shop, order_id: 1234, donation_amount: 10, status: nil).persisted?
    refute Donation.create(shop: @shop, order_id: 1234, donation_amount: 10, status: 'resent').persisted?
    refute Donation.create(shop: @shop, order_id: 1234, donation_amount: 10, status: 'thresholded').persisted?
  end

  test "donation without order saved loads from Shopify and saves the order" do
    order_id = 1234
    donation = Donation.create(shop: @shop, order_id: order_id, donation_amount: 10)

    fake "https://#{@shop}/admin/orders/#{order_id}.json", :body => load_fixture('order.json')
    assert donation.order
    donation.reload
    assert donation.order
  end
end
