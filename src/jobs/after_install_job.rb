class AfterInstallJob < Job
  def perform(shop_name)
    activate_shopify_api(shop_name)
    create_webhook(topic: 'orders/updated', address: "#{base_url}/order")
    create_webhook(topic: 'products/update', address: "#{base_url}/product_update")
    create_webhook(topic: 'app/uninstalled', address: "#{base_url}/uninstall")
  end

  def create_webhook(topic:, address:)
    webhook = ShopifyAPI::Webhook.new({
      topic: topic,
      address: address,
      format: 'json'
    })

    webhook.save!
  rescue => e
    raise unless webhook_already_created?(webhook)
  end

  def base_url
    if ENV['DEVELOPMENT']
      'https://shopify-kevinhughes27.fwd.wf'
    elsif ENV['STAGING']
      'https://taxreceipts-staging.herokuapp.com'
    else
      'https://taxreceipts.herokuapp.com'
    end
  end

  def webhook_already_created?(webhook)
    webhook.errors.messages[:address].present? &&
    webhook.errors.messages[:address].include?("for this topic has already been taken")
  end
end
