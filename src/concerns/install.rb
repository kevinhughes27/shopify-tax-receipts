require 'sinatra/shopify-sinatra-app'
require_relative '../models/charity'
require_relative '../models/product'

class SinatraApp < Sinatra::Base

  # receive uninstall webhook
  post '/uninstall' do
    shopify_webhook do |params|
      Shop.find_by(name: current_shop_name).destroy
      Charity.find_by(shop: current_shop_name).destroy
      Product.where(shop: current_shop_name).destroy_all
    end
  end

  private

  def after_shopify_auth
    shopify_session do
      create_order_webhook
      create_uninstall_webhook
    end
  end

  def create_order_webhook
    order_webhook = ShopifyAPI::Webhook.new({
      topic: "orders/paid",
      address: "#{base_url}/order.json",
      format: "json"
    })

    order_webhook.save!
  rescue => e
    raise unless webhook_already_created?(order_webhook)
  end

  def create_uninstall_webhook
    uninstall_webhook = ShopifyAPI::Webhook.new({
      topic: "app/uninstalled",
      address: "#{base_url}/uninstall",
      format: "json"
    })

    uninstall_webhook.save!
  rescue => e
    raise unless webhook_already_created?(uninstall_webhook)
  end

  def webhook_already_created?(webhook)
    webhook.errors.messages[:address].present? &&
    webhook.errors.messages[:address].include?("for this topic has already been taken")
  end
end
