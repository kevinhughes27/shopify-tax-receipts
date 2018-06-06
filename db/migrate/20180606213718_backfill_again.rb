class BackfillAgain < ActiveRecord::Migration[5.1]
  def change
    Donation.where(order_number: nil).find_each { |donation| backfill(donation) }
  end

  def backfill(donation)
    shop = Shop.find_by(name: donation.shop)
    ShopifyAPI::Session.temp(shop.name, shop.token) do
      donation.update_columns(order_number: donation.order.name)
    end
  rescue => e
    puts "donation #{donation.order_id} failed to backfill"
  end
end
