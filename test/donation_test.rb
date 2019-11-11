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

  test "donation sets donation number before create" do
    donation = Donation.create!(shop: @shop, order_id: 1, donation_amount: 10)
    assert_equal 1, donation.donation_number

    donation.update_column(:donation_number, 20)
    new_donation = Donation.create!(shop: @shop, order_id: 2, donation_amount: 10)
    assert_equal 21, new_donation.donation_number
  end

  test "donation without order saved loads from Shopify and saves the order" do
    order_id = 1234
    donation = Donation.create(shop: @shop, order_id: order_id, donation_amount: 10)

    mock_order_api_call(order_id)
    assert donation.order
    donation.reload
    assert donation.order
  end

  test "dontation template is product template if configured" do
    order_id = 1234
    mock_order_api_call(order_id)
    donation = Donation.create(shop: @shop, order_id: order_id, donation_amount: 10)

    product = Product.where(shop: @shop).first
    product.update(email_template: 'test')

    assert_equal 'test', donation.email_template
  end

  test "dontation template is nil (default to charity template) if product template is nil" do
    order_id = 1234
    mock_order_api_call(order_id)
    donation = Donation.create(shop: @shop, order_id: order_id, donation_amount: 10)

    assert_nil donation.email_template
  end

  test "dontation template is nil (default to charity template) for multiple products" do
    order_id = 1234
    mock_order_api_call(order_id)
    donation = Donation.create(shop: @shop, order_id: order_id, donation_amount: 10)

    Product.stubs(:where).returns([1, 2])

    assert_nil donation.email_template
  end

  test "dontation template is nil (default to charity template) for 0 products (test email)" do
    order_id = 1234
    mock_order_api_call(order_id)
    donation = Donation.create(shop: @shop, order_id: order_id, donation_amount: 10)

    Product.stubs(:where).returns([])

    assert_nil donation.email_template
  end
end
