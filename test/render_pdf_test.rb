require 'test_helper'
require_relative '../src/utils/donation_service'
require_relative '../src/utils/render_pdf'

class RenderPdfTest < ActiveSupport::TestCase

  setup do
    @shop_domain = "apple.myshopify.com"
    activate_shopify_session(@shop_domain, 'token')
    @shop = ShopifyAPI::Shop.new(JSON.parse(load_fixture('shop.json')))
    @charity = Charity.find_by(shop: @shop_domain)
  end

  test "regular_order" do
    order = JSON.parse(load_fixture('order_webhook.json'))
    donation = build_donation(@shop_domain, order, 20)

    pdf = render_pdf(@shop, @charity, donation)
    write_pdf(pdf)
  end

  test "order_no_address" do
    order = JSON.parse(load_fixture('order_no_address.json'))
    donation = build_donation(@shop_domain, order, 20)

    pdf = render_pdf(@shop, @charity, donation)
  end

  test "order_no_billing_address_uses_customer_default_address" do
    order = JSON.parse(load_fixture('order_customer_address.json'))
    donation = build_donation(@shop_domain, order, 20)

    pdf = render_pdf(@shop, @charity, donation)
  end

  test "order_no_zip" do
    order = JSON.parse(load_fixture('order_no_zip.json'))
    donation = build_donation(@shop_domain, order, 20)

    pdf = render_pdf(@shop, @charity, donation)
  end

  test "utf8" do
    @charity.name += 'Ş'
    order = JSON.parse(load_fixture('order_webhook.json'))
    donation = build_donation(@shop_domain, order, 20)

    pdf = render_pdf(@shop, @charity, donation)
  end

  test "void" do
    order = JSON.parse(load_fixture('order_webhook.json'))
    donation = build_donation(@shop_domain, order, 20)
    donation.void!

    pdf = render_pdf(@shop, @charity, donation)
  end

  test "refunded" do
    order = JSON.parse(load_fixture('order_webhook.json'))
    donation = build_donation(@shop_domain, order, 20)
    donation.refunded!

    pdf = render_pdf(@shop, @charity, donation)
  end

  private

  def write_pdf(pdf_string)
    File.open('test.pdf', 'w') { |file| file.write(pdf_string) }
  end
end
