require 'prawn'

class PdfGenerator
  attr_reader :shop, :order, :charity, :donation_amount, :pdf

  FONT_DIR = File.join(Dir.pwd, 'config/fonts/')

  def initialize(shop: nil, order: nil, charity: nil, donation_amount: nil)
    @shop, @charity, @order, @donation_amount = shop, charity, order, donation_amount
    @pdf = Prawn::Document.new
  end

  def generate
    line_size = 12
    font_size = 9

    pdf.move_down line_size / 2
    stroke(1)
    pdf.move_down line_size / 2

    pdf.font_families.update("DejaVuSans" => {
      normal: FONT_DIR + 'DejaVuSans.ttf',
      bold: FONT_DIR + 'DejaVuSans-Bold.ttf',
    })

    pdf.font 'DejaVuSans'

    pdf.font_size font_size * 2
    pdf.text_box charity.name,
      :at => [0,  pdf.cursor], :style => :bold

    pdf.move_down line_size / 2

    pdf.font_size font_size
    pdf.text_box 'OFFICIAL DONATION RECEIPT FOR INCOME TAX PURPOSES',
      :at => [0, pdf.cursor], :align => :right

    pdf.move_down line_size / 2

    pdf.move_down line_size * 10

    box_margin = 65

    if customer_name.present?
      pdf.text_box customer_name,
        :at => [box_margin,  pdf.cursor], :style => :bold

      pdf.font_size font_size
      order_address_lines.each do |line|
        pdf.move_down line_size
        pdf.text_box line, :at => [box_margin,  pdf.cursor]
      end
    end

    pdf.move_down line_size * 10

    pdf.text_box "Donation Details:",
      :at => [box_margin,  pdf.cursor], :style => :bold

    donation_details.each do |line|
      pdf.move_down line_size
      pdf.text_box line, :at => [box_margin,  pdf.cursor]
    end

    pdf.move_down line_size * 2

    pdf.text_box "Donations are tax deductible to the extent permitted by law",
      :at => [box_margin,  pdf.cursor]

    pdf.move_down line_size * 15

    stroke(0.5)

    pdf.move_down line_size * 1

    shop_details.each do |line|
      pdf.move_down line_size
      pdf.text_box line, :at => [box_margin,  pdf.cursor]
    end

    pdf.render
  end

  private

  def stroke(size)
    pdf.move_down(size)
    old_width = pdf.line_width
    pdf.line_width = size
    pdf.horizontal_rule
    pdf.stroke
    pdf.line_width = old_width
    pdf.move_down(size)
  end

  def address
    order["billing_address"]
  end

  def customer_name
    "#{address['first_name']} #{address['last_name']}" if address.present?
  end

  def order_address_lines
    [ address['address1'], address['city'], address['country'], address['zip'] ].compact
  end

  def donation_details
    [
      "Receipt Number: ##{order['number']}",
      "Donation Received: #{Time.parse(order['created_at']).strftime("%B %d, %Y")}",
      "Amount: #{donation_amount}",
      "Date Issued: #{Time.parse(order['created_at']).strftime("%B %d, %Y")}",
      "Place Issued: #{shop.city}"
    ]
  end

  def shop_details
    [
      charity.name,
      "Charity Tax ID # #{charity.charity_id}",
      shop.address1,
      "#{shop.city}, #{shop.province} #{shop.zip}",
    ]
  end
end
