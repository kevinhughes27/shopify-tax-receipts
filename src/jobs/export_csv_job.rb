require 'csv'

class ExportCsvJob < Job
  def perform(shop_name, email_to, start_date, end_date)
    donations = Donation.where(shop: shop_name, created_at: start_date..end_date)

    csv = CSV.generate do |csv|
      csv << ['Order ID', 'Order Number', 'Date', 'Amount', 'Status']
      donations.find_each do |d|
        csv << [d.order_id, d.order_number, d.created_at, d.donation_amount, d.status]
      end
    end

    Pony.mail to: email_to,
              subject: "Donations from #{start_date} to #{end_date}",
              attachments: {"donations.csv" => csv},
              body: "Exported donations attached."
  end
end
