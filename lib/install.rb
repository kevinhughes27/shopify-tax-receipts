require 'sinatra/shopify-sinatra-app'
require_relative 'models/charity'
require_relative 'models/product'

class SinatraApp < Sinatra::Base

  # receive uninstall webhook
  post '/uninstall' do
    webhook_session do |params|
      Charity.where(shop: current_shop_name).destroy_all
      Product.where(shop: current_shop_name).destroy_all
      current_shop.destroy
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
    return if ENV['DEVELOPMENT']

    order_webhook = ShopifyAPI::Webhook.new({
      topic: "orders/create",
      address: "#{base_url}/order.json",
      format: "json"
    })

    order_webhook.save!
  rescue => e
    raise unless webhook_already_created?(order_webhook)
  end

  def create_uninstall_webhook
    return if ENV['DEVELOPMENT']

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
