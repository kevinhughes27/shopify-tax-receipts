require 'sinatra/shopify-sinatra-app'
require './lib/models/product'
require './lib/models/charity'
require './lib/pdf_generator'
require 'pony'
require 'liquid'
require 'raygun4ruby'

Raygun.setup do |config|
  config.api_key = ENV['RAYGUN_APIKEY']
  config.enable_reporting = true
end

class SendReceiptJob
  @queue = :default

  def self.perform(shop_name, token, order)
    begin
      api_session = ShopifyAPI::Session.new(shop_name, token)
      ShopifyAPI::Base.activate_session(api_session)

      donation_product_ids = Product.where(shop: shop_name).pluck(:product_id)

      donations = []
      order['line_items'].each do |item|
        if donation_product_ids.include? item["product_id"]
          donations << item["price"].to_f * item["quantity"].to_i
        end
      end

      unless donations.empty?
        charity = Charity.find_by(shop: shop_name)
        shopify_shop = ShopifyAPI::Shop.current
        donation_amount = donations.sum
        receipt_pdf = PdfGenerator.new(
          shop: shopify_shop,
          charity: charity,
          order: order,
          donation_amount: donation_amount
        ).generate
        deliver_donation_receipt(shopify_shop, order, charity, receipt_pdf)
      end
    rescue Exception => e
      Raygun.track_exception(e)
      raise(e)
    end
  end

  def self.deliver_donation_receipt(shop, order, charity, pdf)
    return unless order["customer"]
    return unless mail_to = order["customer"]["email"]
    return unless order["billing_address"]

    email_body = Liquid::Template.parse(charity.email_template).render(
      order: order,
      charity: charity
    )

    Pony.mail to: mail_to,
              from: shop.email,
              subject: charity.email_subject,
              attachments: {"tax_receipt.pdf" => pdf},
              body: email_body
  end

end
