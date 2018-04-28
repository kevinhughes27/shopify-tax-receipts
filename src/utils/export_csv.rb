require 'csv'

def export_csv(shop_name, start_date, end_date)
  donations = Donation.where(shop: shop_name, created_at: start_date..end_date)

  csv = CSV.generate do |csv|
    csv << ['Order ID', 'Date', 'Amount']
    donations.each do |d|
      csv << [d.order_id, d.created_at, d.donation_amount]
    end
  end

  csv
end
