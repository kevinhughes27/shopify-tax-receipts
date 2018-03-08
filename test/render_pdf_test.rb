require 'test_helper'
require_relative '../src/utils/render_pdf'

class RenderPdfTest < ActiveSupport::TestCase

  setup do
    shop_domain = "apple.myshopify.com"
    activate_shopify_session(shop_domain, 'token')
    @shop = ShopifyAPI::Shop.new(JSON.parse(load_fixture('shop.json')))
    @charity = Charity.find_by(shop: shop_domain)
  end

  test "regular_order" do
    order = JSON.parse(load_fixture('order_webhook.json'))
    pdf = render_pdf(@shop, order, @charity, 20)
    write_pdf(pdf)
  end

  test "order_no_address" do
    order = JSON.parse(load_fixture('order_no_address.json'))
    pdf = render_pdf(@shop, order, @charity, 20)
  end

  test "order_no_billing_address_uses_customer_default_address" do
    order = JSON.parse(load_fixture('order_customer_address.json'))
    pdf = render_pdf(@shop, order, @charity, 20)
  end

  test "order_no_zip" do
    order = JSON.parse(load_fixture('order_no_zip.json'))
    pdf = render_pdf(@shop, order, @charity, 20)
  end

  test "utf8" do
    @charity.name += 'Ş'
    order = JSON.parse(load_fixture('order_webhook.json'))
    pdf = render_pdf(@shop, order, @charity, 20)
  end

  private

  def write_pdf(pdf_string)
    File.open('test.pdf', 'w') { |file| file.write(pdf_string) }
  end
end
