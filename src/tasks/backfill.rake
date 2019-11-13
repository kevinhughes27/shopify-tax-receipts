# usage:
# heroku run bundle exec rake debug_shop\[kevintest3.myshopify.com\]

task :backfill_donation_number, [:shop] do |t, args|
  num = 1
  Donation.where(shop: 'audio-bibles-for-the-blind.myshopify.com').order(:id).find_each do |donation|
    donation.update_column(:donation_number, num)
    num += 1
  end
end
