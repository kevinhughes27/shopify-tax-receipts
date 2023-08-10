require 'csv'

class ExportCsvJob < Job
  class ExportError < StandardError
    def initialize(order_id, error)
      super("Order ID: #{order_id}, Error: #{error.inspect}")
    end
  end

  def perform(shop_name, email_to, start_date, end_date)
    activate_shopify_api(shop_name)

    shop = ShopifyAPI::Shop.current
    charity = Charity.find_by(shop: shop_name)
    donations = Donation.where(shop: shop_name, created_at: start_date..end_date)

    csv = CSV.generate do |csv|
      csv << [
        'Order ID',
        'Order Number',
        'Order Amount',
        'Donation ID',
        'Donation Number',
        'Donation Amount',
        'Status',
        'Received At',
        'Created At',
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
        # 'Phone',
        'Email',
        'Accepts Marketing'
      ]

      donations.find_each do |d|
        csv << [
          d.order_id,
          d.order_number,
          d.order.total_price,
          "#{charity.donation_id_prefix}#{d.id}",
          d.donation_number,
          d.donation_amount,
          d.status,
          d.received_at,
          d.created_at,
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
          # d.order.customer && d.order.customer.phone,
          d.order.customer && d.order.customer.email,
          d.order.customer && d.order.customer.accepts_marketing,
        ]
      rescue => e
        raise ExportError.new(d.order_id, e)
      end
    end

    Pony.mail to: email_to,
              from: "no-reply@shopify-taxreceipts.com",
              subject: "Donations from #{start_date} to #{end_date}",
              attachments: {"donations.csv" => csv},
              body: "Exported donations attached."
  end
end
