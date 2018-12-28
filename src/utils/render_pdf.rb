require 'tilt/liquid'

# mock rails classes for wicked_pdf
module Rails
  def self.env
    'production'
  end

  module VERSION
    MAJOR = 0
  end
end

class WickedPdf
  class Mime
    class Type
      def self.lookup_by_extension(var)
        true
      end
    end
  end
end

require 'wicked_pdf'

def render_pdf(shop, charity, donation)
  template = Tilt::LiquidTemplate.new { |t| charity.pdf_template }

  pdf_content = template.render(
    shop: shop.attributes,
    charity: charity,
    donation: donation,
    order: donation.order_to_liquid,
    donation_amount: donation.donation_amount
  )

  WickedPdf.new.pdf_from_string(
    Tilt::ERBTemplate.new('views/receipt/pdf.erb').render(
      Object.new,
      pdf_content: pdf_content,
      void: donation.void
    )
  )
end
