require 'sidekiq'
require_relative '../../src/jobs/after_install_job'

class BackfillWebhooks < ActiveRecord::Migration[5.2]
  def change
    Shop.find_each do |shop|
      update_webhooks(shop)
    end
  end

  def update_webhooks(shop)
    puts "Updating shop: #{shop.name}"
    create_new_webhooks(shop)
    delete_old_webhook(shop)
  end

  def create_new_webhooks(shop)
    AfterInstallJob.new.perform(shop.name)
  rescue => e
    puts "Error creating webhooks for shop #{shop.name} error: #{e}"
  end

  def delete_old_webhook(shop)
    api_session = ShopifyAPI::Session.new(shop.name, shop.token)
    ShopifyAPI::Base.activate_session(api_session)

    paid_webhooks = ShopifyAPI::Webhook.where(topic: 'orders/paid')
    paid_webhooks.each do |webhook|
      ShopifyAPI::Webhook.delete(webhook.id)
    end
  rescue => e
    puts "Error deleting webhooks for shop #{shop.name} error: #{e}"
  end
end
