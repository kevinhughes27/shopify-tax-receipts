require "test_helper"

class PdfGeneratorTest < ActiveSupport::TestCase

  def setup
    shop_domain = "apple.myshopify.com"
    activate_shopify_session(shop_domain, 'token')
    @shop = ShopifyAPI::Shop.new(JSON.parse(load_fixture('shop.json')))
    @charity = Charity.find_by(shop: shop_domain)
  end

  def test_regular_order
    order = JSON.parse(load_fixture('order_webhook.json'))
    generate_pdf(@shop, order, @charity, 20)
  end

  def test_order_no_address
    order = JSON.parse(load_fixture('order_no_address.json'))
    pdf = generate_pdf(@shop, order, @charity, 20)
  end

  private

  def generate_pdf(shop, order, charity, donation_amount)
    pdf_generator = PdfGenerator.new(shop: shop,
                                     charity: charity,
                                     order: order,
                                     donation_amount: donation_amount)
    pdf_generator.generate
  end

  def write_pdf(pdf_string)
    File.open('test.pdf', 'w') { |file| file.write(pdf_string) }
  end

end
