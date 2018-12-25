class AfterInstallJob
  include Sidekiq::Worker

  def perform(shop_name)
    shop = Shop.find_by(name: shop_name)
    api_session = ShopifyAPI::Session.new(shop.name, shop.token)
    ShopifyAPI::Base.activate_session(api_session)

    create_order_webhook
    create_uninstall_webhook
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
