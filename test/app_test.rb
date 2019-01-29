require "test_helper"

class AppTest < ActiveSupport::TestCase

  def app
    SinatraApp
  end

  setup do
    @shop = "apple.myshopify.com"
    @noop_shop = "banana.myshopify.com"
  end

  test "install" do
    get '/install'
    assert last_response.ok?
  end

  test "home" do
    Donation.create!(shop: @shop, order_id: '1234', donation_amount: 10)

    fake "https://apple.myshopify.com/admin/shop.json", :body => load_fixture('shop.json')

    get '/', {}, 'rack.session' => session

    assert last_response.ok?
  end

  test "donation search" do
    order_json = load_fixture 'order.json'
    order = JSON.parse(order_json)

    Donation.create!(shop: @shop, order_id: '4321', order: order.to_json, donation_amount: 10)

    order['email'] = 'kevinhughes27@gmail.com'
    Donation.create!(shop: @shop, order_id: '5678', order: order.to_json, donation_amount: 10)

    fake "https://apple.myshopify.com/admin/shop.json", :body => load_fixture('shop.json')

    get '/', {donation_search: 'kevin'}, 'rack.session' => session

    assert last_response.ok?
    assert_match "5678", last_response.body
    refute_match "4321", last_response.body
  end

  test "product search" do
    Product.create!(shop: @shop, product_id: '9999', shopify_product: {title: 'beans', body_html: 'magical fruit'}.to_json)

    fake "https://apple.myshopify.com/admin/shop.json", :body => load_fixture('shop.json')

    get '/', {product_search: 'beans'}, 'rack.session' => session

    assert last_response.ok?
    assert_match "9999", last_response.body
    refute_match "632910392", last_response.body
  end

  test "view" do
    order_id = 1234
    donation = Donation.create!(shop: @shop, order_id: order_id, donation_amount: 10)

    fake "https://apple.myshopify.com/admin/orders/#{order_id}.json", :body => load_fixture('order.json')
    fake "https://apple.myshopify.com/admin/shop.json", :body => load_fixture('shop.json')

    get "/view?id=#{donation.id}", {}, 'rack.session' => session

    assert last_response.ok?
  end

  test "resend" do
    order_id = 1234
    donation = Donation.create!(shop: @shop, order_id: order_id, donation_amount: 10)

    fake "https://apple.myshopify.com/admin/orders/#{order_id}.json", :body => load_fixture('order.json')
    fake "https://apple.myshopify.com/admin/shop.json", :body => load_fixture('shop.json')

    Pony.expects(:mail).once

    params = {id: donation.id}
    post '/resend', params, 'rack.session' => session

    assert last_response.redirect?
    assert_equal 'Email resent!', last_request.env['x-rack.flash'][:notice]
    assert_equal 'resent', donation.reload.status
  end

  test "send thresholded" do
    order_id = 1234
    donation = Donation.create!(shop: @shop, status: 'thresholded', order_id: order_id, donation_amount: 10)

    fake "https://apple.myshopify.com/admin/orders/#{order_id}.json", :body => load_fixture('order.json')
    fake "https://apple.myshopify.com/admin/shop.json", :body => load_fixture('shop.json')

    Pony.expects(:mail).once

    params = {id: donation.id}
    post '/resend', params, 'rack.session' => session

    assert last_response.redirect?
    assert_equal 'Email sent!', last_request.env['x-rack.flash'][:notice]
    assert_nil donation.reload.status
  end

  test "cant resend void" do
    order_id = 1234
    donation = Donation.create!(shop: @shop, order_id: order_id, donation_amount: 10, status: 'void')

    fake "https://apple.myshopify.com/admin/shop.json", :body => load_fixture('shop.json')

    params = {id: donation.id}
    post '/resend', params, 'rack.session' => session

    assert last_response.redirect?
    assert_equal 'Donation is void', last_request.env['x-rack.flash'][:error]
  end

  test "void" do
    order_id = 1234
    donation = Donation.create!(shop: @shop, order_id: order_id, donation_amount: 10)

    fake "https://apple.myshopify.com/admin/orders/#{order_id}.json", :body => load_fixture('order.json')
    fake "https://apple.myshopify.com/admin/shop.json", :body => load_fixture('shop.json')

    Pony.expects(:mail).once

    params = {id: donation.id}
    post '/void', params, 'rack.session' => session

    assert last_response.redirect?
    assert_equal 'Donation voided', last_request.env['x-rack.flash'][:notice]
    assert donation.reload.void
  end

  test "can't void void" do
    order_id = 1234
    donation = Donation.create!(shop: @shop, status: 'void', order_id: order_id, donation_amount: 10)

    fake "https://apple.myshopify.com/admin/orders/#{order_id}.json", :body => load_fixture('order.json')
    fake "https://apple.myshopify.com/admin/shop.json", :body => load_fixture('shop.json')

    Pony.expects(:mail).never

    params = {id: donation.id}
    post '/void', params, 'rack.session' => session

    assert last_response.redirect?
    assert_equal 'Donation is void', last_request.env['x-rack.flash'][:error]
    assert donation.reload.void
  end

  test "void thresholded doesn't email" do
    order_id = 1234
    donation = Donation.create!(shop: @shop, status: 'thresholded', order_id: order_id, donation_amount: 10)

    fake "https://apple.myshopify.com/admin/orders/#{order_id}.json", :body => load_fixture('order.json')
    fake "https://apple.myshopify.com/admin/shop.json", :body => load_fixture('shop.json')

    Pony.expects(:mail).never

    params = {id: donation.id}
    post '/void', params, 'rack.session' => session

    assert last_response.redirect?
    assert_equal 'Donation voided', last_request.env['x-rack.flash'][:notice]
    assert donation.reload.void
  end

  test "preview_email" do
    fake "https://apple.myshopify.com/admin/shop.json", :body => load_fixture('shop.json')

    get '/preview_email', {template: 'order {{ order.name }}'}, 'rack.session' => session

    assert last_response.ok?
    assert_equal "order #1001", JSON.parse(last_response.body)['email_body']
  end

  test "test_email" do
    charity = Charity.find_by(shop: @shop)

    fake "https://apple.myshopify.com/admin/shop.json", :body => load_fixture('shop.json')
    Pony.expects(:mail).with(has_entry(body: "hello #{charity.name}"))

    get '/test_email', {email_template: 'hello {{ charity.name }}'}, 'rack.session' => session
    assert last_response.ok?
  end

  test "test_html_email" do
    charity = Charity.find_by(shop: @shop)

    fake "https://apple.myshopify.com/admin/shop.json", :body => load_fixture('shop.json')
    Pony.expects(:mail).with(has_entry(html_body: "<html>hello #{charity.name}</html>"))

    get '/test_email', {email_template: '<html>hello {{ charity.name }}</html>'}, 'rack.session' => session
    assert last_response.ok?
  end

  test "test_void_email" do
    charity = Charity.find_by(shop: @shop)

    fake "https://apple.myshopify.com/admin/shop.json", :body => load_fixture('shop.json')
    Pony.expects(:mail).with(has_entry(body: "goodbye #{charity.name}"))

    get '/test_email', {void_email_template: 'goodbye {{ charity.name }}'}, 'rack.session' => session
    assert last_response.ok?
  end

  test "preview_pdf" do
    charity = Charity.find_by(shop: @shop)

    fake "https://apple.myshopify.com/admin/shop.json", :body => load_fixture('shop.json')

    post '/preview_pdf', {template: 'hello {{ charity.name }}', status: 'default'}, 'rack.session' => session
    assert last_response.ok?

    text = PDF::Inspector::Text.analyze(last_response.body)
    assert_equal text.strings.join, "hello #{charity.name}"
  end

  test "preview_pdf (void)" do
    charity = Charity.find_by(shop: @shop)

    fake "https://apple.myshopify.com/admin/shop.json", :body => load_fixture('shop.json')

    post '/preview_pdf', {template: 'hello {{ charity.name }}', status: 'void'}, 'rack.session' => session
    assert last_response.ok?

    text = PDF::Inspector::Text.analyze(last_response.body)
    assert_equal text.strings.join, "VOIDhello #{charity.name}"
  end

  test "export" do
    Donation.create!(shop: @shop, order_id: 1234, donation_amount: 10, created_at: Time.now - 5.days)
    Donation.create!(shop: @shop, order_id: 5678, donation_amount: 10)

    fake "https://apple.myshopify.com/admin/shop.json", :body => load_fixture('shop.json')
    fake "https://apple.myshopify.com/admin/orders/1234.json", :body => load_fixture('order.json')
    fake "https://apple.myshopify.com/admin/orders/5678.json", :body => load_fixture('order.json')

    params = {email_to: 'kevin@example.com', start_date: Time.now - 3.days, end_date: Time.now + 2.days}
    post '/export', params, 'rack.session' => session

    assert last_response.redirect?

    mail = Mail::TestMailer.deliveries.last
    csv = mail.attachments[0].read

    refute_match "1234", csv
    assert_match "5678", csv
  end

  private

  def session
    { shopify: {shop: @shop, token: 'token'} }
  end
end
