# usage:
# heroku run bundle exec rake backfill_donation_number\[kevintest3.myshopify.com\]

task :backfill_donation_number, [:shop] do |t, args|
  num = 1
  Donation.where(shop: shop).order(:id).find_each do |donation|
    donation.update_column(:donation_number, num)
    num += 1
  end
end
