task :backfill_donation_number do
  Shop.find_each { |shop| backfill_donation_number(shop) }
end

def backfill_donation_number(shop)
  puts "Backfilling shop: #{shop.name}"

  num = 1
  Donation.where(shop: shop.name).order(:id).find_each do |donation|
    donation.update_column(:donation_number, num)
    num += 1
  end
rescue => e
  puts "Error backfilling for shop #{shop.name} error: #{e}"
end
