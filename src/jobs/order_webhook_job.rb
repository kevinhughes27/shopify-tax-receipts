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

  rescue ActiveResource::ResourceNotFound => e
    if Time.parse(order['created_at'] ) <= 60.days.ago
      puts "Order older than 60 days and user has not re-authed"
    else
      raise e
    end
  end

  # order_paid
  def order_paid(shop_name, order)
    return unless order['email'].present?
    return unless order['customer']
    return unless order['billing_address']

    donations = donations_from_order(shop_name, order)
    donation_amount = donations.sum
    return if donations.empty?

    charity = Charity.find_by(shop: shop_name)
    return if charity.nil?

    donation = Donation.new(
      shop: shop_name,
      order: order.to_json,
      order_id: order['id'],
      order_number: order['name'],
      donation_amount: sprintf( "%0.02f", donation_amount)
    )

    if charity.receipt_threshold.present? && donation_amount < charity.receipt_threshold
      donation.status = 'thresholded'
    end

    donation.save!

    unless donation.thresholded
      activate_shopify_api(shop_name)
      shopify_shop = ShopifyAPI::Shop.current

      receipt_pdf = render_pdf(shopify_shop, charity, donation)
      deliver_donation_receipt(shopify_shop, charity, donation, receipt_pdf)
    end
  end

  # order_updated
  def order_updated(shop_name, order, existing_donation)
    activate_shopify_api(shop_name)
    shopify_shop = ShopifyAPI::Shop.current
    charity = Charity.find_by(shop: shop_name)
    donations = donations_from_order(shop_name, order)
    donation_amount = donations.sum

    new_donation = Donation.new(
      shop: shop_name,
      order: order.to_json,
      order_id: order['id'],
      order_number: order['name'],
      donation_amount: sprintf( "%0.02f", donation_amount)
    )

    # set attributes for comparison
    new_donation.id = existing_donation.id
    new_donation.created_at = existing_donation.created_at
    new_donation.status = existing_donation.status
    new_donation.original_donation = existing_donation.original_donation if existing_donation.status == 'update'

    old_receipt_pdf = render_pdf(shopify_shop, charity, existing_donation)
    new_receipt_pdf = render_pdf(shopify_shop, charity, new_donation)

    update_required = false
    update_required ||= email_changed?(existing_donation, new_donation)
    update_required ||= pdf_changed?(old_receipt_pdf, new_receipt_pdf)

    if update_required
      # clear attributes for comparison
      new_donation.id = nil
      new_donation.created_at = nil
      new_donation.status = 'update'
      new_donation.original_donation = existing_donation

      if existing_donation.thresholded && charity.receipt_threshold.present? && donation_amount < charity.receipt_threshold
        new_donation.status = 'thresholded'
        new_donation.original_donation = nil
      elsif existing_donation.thresholded
        new_donation.status = nil
        new_donation.original_donation = nil
      end

      Donation.transaction do
        existing_donation.void!
        new_donation.save!
      end

      unless new_donation.thresholded
        update_receipt_pdf = render_pdf(shopify_shop, charity, new_donation)
        deliver_updated_receipt(shopify_shop, charity, new_donation, update_receipt_pdf)
      end
    end
  end

  # order_refunded
  def order_refunded(shop_name, order, existing_donation)
    was_thresholded = existing_donation.thresholded
    existing_donation.void!

    unless was_thresholded
      activate_shopify_api(shop_name)
      shopify_shop = ShopifyAPI::Shop.current
      charity = Charity.find_by(shop: shop_name)

      receipt_pdf = render_pdf(shopify_shop, charity, existing_donation)
      deliver_void_receipt(shopify_shop, charity, existing_donation, receipt_pdf)
    end
  end

  # order_partially_refunded
  def order_partially_refunded(shop_name, order, existing_donation)
    refunded_donations = donations_from_refund(shop_name, order)
    refunded_amount = refunded_donations.sum
    return if refunded_donations.empty?

    new_amount = existing_donation.donation_amount - refunded_amount

    new_donation = Donation.new(
      status: 'update',
      shop: shop_name,
      order: order.to_json,
      order_id: order['id'],
      order_number: order['name'],
      donation_amount: sprintf( "%0.02f", new_amount)
    )

    if existing_donation.thresholded
      new_donation.status = 'thresholded'
    end

    Donation.transaction do
      existing_donation.void!
      new_donation.save!
    end

    unless new_donation.thresholded
      activate_shopify_api(shop_name)
      shopify_shop = ShopifyAPI::Shop.current
      charity = Charity.find_by(shop: shop_name)

      new_receipt_pdf = render_pdf(shopify_shop, charity, new_donation)
      deliver_updated_receipt(shopify_shop, charity, new_donation, new_receipt_pdf)
    end
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
      donation_product = donation_products.detect do |product|
        product.product_id == item["product_id"]
      end

      if donation_product
        donations << item["price"].to_f * item["quantity"].to_i * (donation_product.percentage / 100.0)
      end
    end

    donations
  end

  def donations_from_refund(shop_name, order)
    donation_products = Product.where(shop: shop_name)

    donations = []

    order["refunds"].each do |refund|
      refund["refund_line_items"].each do |refund_item|
        line_item = refund_item["line_item"]

        donation_product = donation_products.detect do |product|
          product.product_id == line_item["product_id"]
        end

        if donation_product
          donations << line_item["price"].to_f * refund_item["quantity"].to_i * (donation_product.percentage / 100.0)
        end
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

    changed = old_compare_string != new_compare_string
    notify_pdf_change(old, new) if changed
    changed
  end

  def notify_pdf_change(old, new)
    Pony.mail to: 'kevinhughes27@gmail.com',
              subject: 'Shopify Tax Receipts PDF Changed',
              body: "pdf change",
              attachments: {
                "old.pdf" => old,
                "new.pdf" => new
              }
  end
end
