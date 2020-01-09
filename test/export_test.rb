require "test_helper"

class ExportTest < ActiveSupport::TestCase
  setup do
    @shop = "apple.myshopify.com"
  end

  test "export job" do
    Donation.create!(shop: @shop, order_id: 1234, donation_amount: 10, created_at: Time.now - 5.days)
    Donation.create!(shop: @shop, order_id: 5678, donation_amount: 10)

    mock_shop_api_call
    mock_order_api_call('1234')
    mock_order_api_call('5678')

    start_date = Time.now - 3.days
    end_date = Time.now + 2.days

    ExportCsvJob.new.perform(@shop, 'kevin@example.com', start_date, end_date)

    mail = Mail::TestMailer.deliveries.last
    csv = mail.attachments[0].read

    refute_match "1234", csv
    assert_match "5678", csv
  end

  test "raises custom error with order_id" do
    Donation.create!(shop: @shop, order_id: 1234, donation_amount: 10, created_at: Time.now - 5.days)
    Donation.create!(shop: @shop, order_id: 5678, donation_amount: 10)

    mock_shop_api_call
    mock_order_api_call('1234')

    start_date = Time.now - 3.days
    end_date = Time.now + 2.days

    error = assert_raise ExportCsvJob::ExportError do
      ExportCsvJob.new.perform(@shop, 'kevin@example.com', start_date, end_date)
    end

    assert_match "Order ID: 5678, Error:", error.message
  end
end
