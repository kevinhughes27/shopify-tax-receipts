class SinatraApp < Sinatra::Base
  # {
  #   "shop_id": "<ID>",
  #   "shop_domain": "<domain>",
  #   "customer": {
  #     "id": "<ID>",
  #     "email": "<email>",
  #     "phone": "<phone>"
  #   },
  #   "orders_to_redact": ["<order ID>", "<order ID>", "<order ID>"]
  # }
  get '/customers/redact' do
    # no customer PII is stored.
    status 200
  end

  # sent 48 hours after a store owner uninstalls your app
  # {
  #   "shop_id": "<ID>",
  #   "shop_domain": "<domain>"
  # }
  get '/shop/redacted' do
    webhook_session do |shop_name, params|
      Shop.where(name: shop_name).destroy_all
      Charity.where(shop: shop_name).destroy_all
      Product.where(shop: shop_name).destroy_all
      Donation.where(shop: shop_name).destroy_all
    end
  end

  # {
  #   "shop_id": "<ID>",
  #   "shop_domain": "<domain>",
  #   "customer": {
  #     "id": "<ID>",
  #     "email": "<email>",
  #     "phone": "<phone>"
  #   },
  #   "orders_requested": ["<order ID>", "<order ID>", "<order ID>"]
  # }
  get '/customers/data_request' do
    webhook_session do |shop_name, params|
      Pony.mail to: 'kevinhughes27@gmail.com',
                subject: 'Shopify Tax Receipts GDPR Data Request',
                body: JSON.pretty_generate(params)
    end
  end
end
