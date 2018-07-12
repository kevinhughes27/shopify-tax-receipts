class UpdateWebhooks < ActiveRecord::Migration[5.1]
  def change
    Shop.find_each do |shop|
      update_webhook(shop)
    end
  end

  def update_webhook(shop)
    api_session = ShopifyAPI::Session.new(shop.name, shop.token)
    ShopifyAPI::Base.activate_session(api_session)
    create_new_webhook(shop)
    delete_old_webhook(shop)
  end

  def create_new_webhook(shop)
    paid_webhook = ShopifyAPI::Webhook.new({topic: 'orders/paid', address: 'https://taxreceipts.herokuapp.com/order.json', format: 'json'})
    paid_webhook.save!
  rescue => e
    puts "Error creating webhook for shop #{shop.name} error: #{e}"
  end

  def delete_old_webhook(shop)
    # this returns a collection plus there could be multiple (http vs https...)
    create_webhooks = ShopifyAPI::Webhook.where(topic: 'orders/create')
    create_webhooks.each do |webhook|
      ShopifyAPI::Webhook.delete(webhook.id)
    end
  rescue => e
    puts "Error deleting webhooks for shop #{shop.name} error: #{e}"
  end
end
