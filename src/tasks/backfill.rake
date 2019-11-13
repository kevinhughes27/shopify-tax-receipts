task :backfill_donation_number do
  Donation.where(donation_number: nil).order(:id).find_each do |donation|
    donation.send(:set_donation_number)
    donation.save!
  end
end
