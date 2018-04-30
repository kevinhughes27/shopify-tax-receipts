require 'test_helper'
require 'set'
require 'tempfile'
require_relative '../db/migrate/20180430144346_update_templates'

class TemplateMigrationTest < ActiveSupport::TestCase

  setup do
    reset_db
    activate_shopify_session('apple.myshopify.com', 'token') # required to initiatilize new ShopifyAPI Objects ...
  end

  PRE_BROKEN_TEMPLATES = [
    271, 496
  ]

  test "transform includes all used fields" do
    liquid_tag_regex = /{{[^}]*}}/

    found_vars = Set.new

    templates_csv.each_line("\n") do |row|
      columns = row.split("|")
      id = columns[0]
      email_template = columns[1]
      pdf_template = columns[2]

      email_vars = email_template.scan(liquid_tag_regex)
      pdf_vars = pdf_template.scan(liquid_tag_regex)

      email_vars.each { |v| found_vars.add(v.strip) }
      pdf_vars.each { |v| found_vars.add(v.strip) }
    end

    handled_vars = UpdateTemplates::TRANSFORMATIONS.keys + UpdateTemplates::IGNORE
    unhandled_vars = found_vars - Set.new(handled_vars)
    assert_equal [], unhandled_vars.to_a
  end

  # test "migration" do
  #   create_charities
  #   run_migration
  #   render_all
  # end

  def templates_csv
    filename = 'test/fixtures/templates.csv'
    file = File.new(filename, 'r')
  rescue
    charity = Charity.new
    temp_file = Tempfile.new('templates.csv')
    temp_file.write("1, #{charity.email_template.inspect}, #{charity.pdf_template.inspect}\n")
    temp_file.rewind
    temp_file
  end

  def create_charities
    templates_csv.each_line("\n") do |row|
      columns = row.split("|")
      id = columns[0]
      email_template = columns[1]
      pdf_template = columns[2]

      Charity.create!(
        id: id,
        name: id,
        charity_id: id,
        shop: id,
        email_template: email_template,
        pdf_template: pdf_template
      )
    end

    assert_equal 281, Charity.count
  end

  def run_migration
    UpdateTemplates.up
  end

  def render_all
    Charity.find_each { |charity| render_templates(charity) }
  end

  def render_templates(charity)
    if PRE_BROKEN_TEMPLATES.include?(charity.id)
      puts "skipping charity #{charity.id} due to an exisiting error"
      return
    end

    puts "rendering charity #{charity.id}"

    # render email template
    template = Tilt::LiquidTemplate.new { |t| charity.email_template }
    template.render(charity.email_template, layout: false, locals: {charity: charity, donation: mock_donation})

    # render pdf template
    pdf_string = render_pdf(shop, nil, charity, mock_donation)

    # save to file
    File.open('test.pdf', 'w') { |file| file.write(pdf_string) }
  end

  def shop
    attributes = JSON.parse(load_fixture('shop.json'))
    ShopifyAPI::Shop.new(attributes)
  end

  def mock_donation
    build_donation('apple.myshopify.com', mock_order, 20.00)
  end

  def mock_order
    JSON.parse( File.read(File.join('test', 'fixtures/order_webhook.json')) )
  end
end
