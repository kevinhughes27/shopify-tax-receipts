class AfterInstallJob < Job
  def perform(shop_name)
    activate_shopify_api(shop_name)
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

  def base_url
    if ENV['DEVELOPMENT']
      'https://shopify-kevinhughes27.fwd.wf'
    else
      'https://taxreceipts.herokuapp.com'
    end
  end

  def webhook_already_created?(webhook)
    webhook.errors.messages[:address].present? &&
    webhook.errors.messages[:address].include?("for this topic has already been taken")
  end
end
