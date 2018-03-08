require 'tilt/liquid'
require 'wicked_pdf'

def render_pdf(shop, order, charity, donation_amount)
  order['created_at'] = Time.parse(order['created_at']).strftime("%B %d, %Y")
  order['billing_address'] ||= order.dig('default_address')

  template = Tilt::LiquidTemplate.new { |t| charity.pdf_template }
  pdf_content = template.render(
    shop: shop.attributes,
    order: order,
    charity: charity,
    donation_amount: donation_amount
  )

  WickedPdf.new.pdf_from_string(
    Tilt::ERBTemplate.new('views/receipt/pdf.erb').render(Object.new, pdf_content: pdf_content)
  )
end
