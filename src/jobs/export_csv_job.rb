require 'csv'

class ExportCsvJob < Job
  def perform(shop_name, email_to, start_date, end_date)
    activate_shopify_api(shop_name)

    shop = ShopifyAPI::Shop.current
    charity = Charity.find_by(shop: shop_name)
    donations = Donation.where(shop: shop_name, created_at: start_date..end_date)

    csv = CSV.generate do |csv|
      csv << [
        'Order ID',
        'Order Number',
        'Received At',
        'Created At',
        'Donation Amount',
        'Order Amount',
        'Receipt ID',
        'Status',
        'First Name',
        'Last Name',
        'Company Name',
        'Address 1',
        'Address 2',
        'City',
        'Province',
        'Country',
        'Zip',
        'Customer ID',
        'Phone',
        'Email',
        'Accepts Marketing'
      ]

      donations.find_each do |d|
        csv << [
          d.order_id,
          d.order_number,
          d.received_at,
          d.created_at,
          d.donation_amount,
          d.order.total_price,
          "#{charity.donation_id_prefix}#{d.id}",
          d.status,
          d.first_name,
          d.last_name,
          d.company,
          d.address1,
          d.address2,
          d.city,
          d.province,
          d.country,
          d.zip,
          d.order.customer && d.order.customer.id,
          d.order.customer && d.order.customer.phone,
          d.order.customer && d.order.customer.email,
          d.order.customer && d.order.customer.accepts_marketing,
        ]
      end
    end

    Pony.mail to: email_to,
              from: charity.email_from || shop.email,
              subject: "Donations from #{start_date} to #{end_date}",
              attachments: {"donations.csv" => csv},
              body: "Exported donations attached."
  end
end
