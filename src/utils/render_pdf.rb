require 'tilt/liquid'
require 'wicked_pdf'

def render_pdf(shop, charity, donation)
  template = Tilt::LiquidTemplate.new(default_encoding: 'utf-8') { |t| charity.pdf_template }

  pdf_content = template.render(
    shop: shop.attributes,
    charity: charity,
    donation: donation,
    order: donation.order_to_liquid,
    donation_amount: donation.donation_amount
  )

  WickedPdf.new.pdf_from_string(
    Tilt::ERBTemplate.new('views/receipt/pdf.erb', default_encoding: 'utf-8').render(
      Object.new,
      pdf_content: pdf_content,
      void: donation.void
    )
  )
end
