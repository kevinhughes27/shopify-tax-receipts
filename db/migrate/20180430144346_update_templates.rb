class UpdateTemplates < ActiveRecord::Migration[5.1]
  TRANSFORMATIONS = {
    "{{ order['number'] }}" => "{{ donation.order_number }}",
    "{{ order['created_at'] }}" => "{{ donation.created_at }}",
    "{{ order['billing_address']['first_name'] }}" => "{{ donation.first_name }}",
    "{{ order['billing_address']['last_name'] }}" => "{{ donation.last_name }}",
    "{{ order['customer']['first_name'] }}" => "{{ donation.first_name }}",
    "{{ order['customer']['last_name'] }}" => "{{ vdonation.last_name}}",
    "{{ address['first_name'] }}" => "{{ donation.first_name }}",
    "{{ address['last_name'] }}" => "{{ donation.last_name }}",
    "{{ address['address1'] }}" => "{{ donation.address1 }}",
    "{{ address['city'] }}" => "{{ donation.city }}",
    "{{ address['country'] }}" => "{{ donation.country }}",
    "{{ address['zip' }}" => "{{ donation.address.zip }}",
    "{{ customer.first_name }}" => "{{ donation.first_name }}",
    "{{ donation_amount }}" => "{{ donation.donation_amount }}",
  }

  IGNORE = [
    "{{ email_title }}",
    "{{ charity['name'] }}",
    "{{ charity.name }}",
    "{{ charity.charity_id }}",
    "{{ shop['logo'] }}",
    "{{ shop['city'] }}",
    "{{ shop['address1'] }}",
    "{{ shop.email_accent_color }}",
    "{{ donation.first_name }}",
    "{{ donation.last_name }}"
  ]

  UNHANDLED = [
    "{{ shop['province'] }}",
    "{{ shop['zip'] }}",
    "{{ order['total_price'] }}",
    "{{ order['total_price' }}",
    "{{store url=\"\"}}",
    "{{var logo_alt}}",
    "{{ address['state'] }}",
    "{{ address['zip'] }}",
    "{{\"last_name }}",
    "{{ \"address1\"}}",
    "{{\"address2\" }}",
    "{{ \"city\"}}",
    "{{\"province\" }}",
    "{{\"zip\" }}",
    "{{ address['province'] }}",
    "{{ order['name'] }}",
    "{{ charity['name'], Inc. }}",
    "{{shop.email_logo_url}}",
    "{{ shop.name }}",
    "{{ shop.email_logo_width }}",
    "{{shop.url}}",
    "{{ order_name }}",
    "{{ email_body }}",
    "{{ order_status_url }}",
    "{{ shop.url }}",
    "{{ order_number }}",
    "{{ order['customer']['email'] }}",
    "{{ order ['customer']['phone'] }}",
    "{{ order['billing_address']['address1'] }}",
    "{{ order['billing_address']['address2'] }}",
    "{{ order['billing_address']['city'] }}",
    "{{ order['billing_address']['province'] }}",
    "{{ order['billing_address']['country'] }}",
    "{{ order['billing_address']['zip'] }}",
    "{{ attribute['name'] }}",
    "{{ attribute['value'] }}",
    "{{ line_item.title }}",
    "{{ order['note'] }}"
  ]

  def self.up
    # update email templates
    Charity.where.not(email_template: nil).find_each do |charity|
      new_template = apply_transformations(charity.email_template)
      charity.update_columns(email_template: new_template)
    end

    # update pdf templates
    Charity.where.not(pdf_template: nil).find_each do |charity|
      new_template = apply_transformations(charity.pdf_template)
      charity.update_columns(pdf_template: new_template)
    end
  end

  def self.apply_transformations(template)
    TRANSFORMATIONS.each do |old_value, new_value|
      puts "updating #{old_value} to #{new_value}"
      template.gsub!(old_value, new_value)
    end

    template
  end
end
