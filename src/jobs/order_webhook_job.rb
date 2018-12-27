class OrderWebhookJob < Job
  def perform(shop_name, order)
    existing_donation = load_most_recent_donation(shop_name, order['id'])
    return if existing_donation && existing_donation.void

    status = order['financial_status']

    if status == 'paid' && existing_donation.nil?
       order_paid(shop_name, order)

    elsif status == 'paid' && existing_donation
      order_updated(shop_name, order, existing_donation)

    elsif status == 'refunded' && existing_donation
      order_refunded(shop_name, order, existing_donation)

    elsif status == 'partially_refunded' && existing_donation
      order_partially_refunded(shop_name, order, existing_donation)
    end
  end

  # order_paid
  def order_paid(shop_name, order)
    return unless order['customer']
    return unless order['customer']['email']

    donations = donations_from_order(shop_name, order)
    donation_amount = donations.sum
    return if donations.empty?

    charity = Charity.find_by(shop: shop_name)
    return if charity.nil?

    activate_shopify_api(shop_name)
    shopify_shop = ShopifyAPI::Shop.current

    return if charity.receipt_threshold.present? && donation_amount < charity.receipt_threshold

    donation = Donation.create!(
      shop: shop_name,
      order: order.to_json,
      order_id: order['id'],
      order_number: order['name'],
      donation_amount: sprintf( "%0.02f", donation_amount)
    )

    receipt_pdf = render_pdf(shopify_shop, charity, donation)
    deliver_donation_receipt(shopify_shop, charity, donation, receipt_pdf)
  end

  # order_updated
  def order_updated(shop_name, order, existing_donation)
    activate_shopify_api(shop_name)
    shopify_shop = ShopifyAPI::Shop.current
    charity = Charity.find_by(shop: shop_name)
    donations = donations_from_order(shop_name, order)
    donation_amount = donations.sum

    new_donation = Donation.new(
      id: existing_donation.id, # needed for comparison
      shop: shop_name,
      order: order.to_json,
      order_id: order['id'],
      order_number: order['name'],
      donation_amount: sprintf( "%0.02f", donation_amount)
    )

    old_receipt_pdf = render_pdf(shopify_shop, charity, existing_donation)
    new_receipt_pdf = render_pdf(shopify_shop, charity, new_donation)

    send_update = false
    send_update ||= email_changed?(existing_donation, new_donation)
    send_update ||= pdf_changed?(old_receipt_pdf, new_receipt_pdf)

    if send_update
      new_donation.id = nil
      new_donation.status = 'update'
      new_donation.original_donation = existing_donation

      Donation.transaction do
        existing_donation.void!
        new_donation.save!
      end

      deliver_updated_receipt(shopify_shop, charity, new_donation, new_receipt_pdf)
    end
  end

  # order_refunded
  def order_refunded(shop_name, order, existing_donation)
  end

  # order_partially_refunded
  def order_partially_refunded(shop_name, order, existing_donation)
  end

  private

  def load_most_recent_donation(shop_name, order_id)
    Donation
      .where(shop: shop_name, order_id: order_id)
      .order(id: :desc)
      .first
    end

  def donations_from_order(shop_name, order)
    donation_products = Product.where(shop: shop_name)

    donations = []

    order["line_items"].each do |item|
      donation_product = donation_products.detect { |product| product.product_id == item["product_id"] }
      if donation_product
        donations << item["price"].to_f * item["quantity"].to_i * (donation_product.percentage / 100.0)
      end
    end

    donations
  end

  def email_changed?(old_donation, new_donation)
    old_donation.email != new_donation.email
  end

  def pdf_changed?(old, new)
    old_start_idx = old.index('endobj')
    old_end_idx = old.length
    old_compare_string = old.slice(old_start_idx, old_end_idx)

    new_start_idx = new.index('endobj')
    new_end_idx = new.length
    new_compare_string = new.slice(new_start_idx, new_end_idx)

    old_compare_string != new_compare_string
  end
end
