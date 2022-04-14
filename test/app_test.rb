require "test_helper"

class AppTest < ActiveSupport::TestCase

  def app
    SinatraApp
  end

  setup do
    @shop = "apple.myshopify.com"
    @noop_shop = "banana.myshopify.com"
  end

  test "login" do
    get '/login'
    assert last_response.ok?
  end

  test "home" do
    order_json = load_fixture 'order.json'
    Donation.create!(shop: @shop, order_id: '1234', order: order_json, donation_amount: 10)

    mock_shop_api_call

    get '/', {}, 'rack.session' => session

    assert last_response.ok?
  end

  test "donation search" do
    order_json = load_fixture 'order.json'
    order = JSON.parse(order_json)

    Donation.create!(shop: @shop, order_id: '4321', order: order.to_json, donation_amount: 10)

    order['email'] = 'kevinhughes27@gmail.com'
    Donation.create!(shop: @shop, order_id: '5678', order: order.to_json, donation_amount: 10)

    mock_shop_api_call

    get '/', {donation_search: 'kevin'}, 'rack.session' => session

    assert last_response.ok?
    assert_match "5678", last_response.body
    refute_match "4321", last_response.body
  end

  test "product search" do
    Product.create!(shop: @shop, product_id: '9999', shopify_product: {title: 'beans', body_html: 'magical fruit'}.to_json)

    mock_shop_api_call

    get '/', {product_search: 'beans'}, 'rack.session' => session

    assert last_response.ok?
    assert_match "9999", last_response.body
    refute_match "632910392", last_response.body
  end

  test "view" do
    order_id = 1234
    donation = Donation.create!(shop: @shop, order_id: order_id, donation_amount: 10)

    mock_order_api_call(order_id)
    mock_shop_api_call

    get "/view?id=#{donation.id}", {}, 'rack.session' => session

    assert last_response.ok?
  end

  test "resend" do
    order_id = 1234
    donation = Donation.create!(shop: @shop, order_id: order_id, donation_amount: 10)

    mock_order_api_call(order_id)
    mock_shop_api_call

    Pony.expects(:mail).once

    params = {id: donation.id, authenticity_token: token}
    post '/resend', params, 'rack.session' => session

    assert last_response.redirect?
    assert_equal 'Email resent!', last_request.session[:flash][:notice]
    assert_equal 'resent', donation.reload.status
  end

  test "send thresholded" do
    order_id = 1234
    donation = Donation.create!(shop: @shop, status: 'thresholded', order_id: order_id, donation_amount: 10)

    mock_order_api_call(order_id)
    mock_shop_api_call

    Pony.expects(:mail).once

    params = {id: donation.id, authenticity_token: token}
    post '/resend', params, 'rack.session' => session

    assert last_response.redirect?
    assert_equal 'Email sent!', last_request.session[:flash][:notice]
    assert_nil donation.reload.status
  end

  test "cant resend void" do
    order_id = 1234
    donation = Donation.create!(shop: @shop, order_id: order_id, donation_amount: 10, status: 'void')

    mock_shop_api_call

    params = {id: donation.id, authenticity_token: token}
    post '/resend', params, 'rack.session' => session

    assert last_response.redirect?
    assert_equal 'Donation is void', last_request.session[:flash][:error]
  end

  test "void" do
    order_id = 1234
    donation = Donation.create!(shop: @shop, order_id: order_id, donation_amount: 10)

    mock_order_api_call(order_id)
    mock_shop_api_call

    Pony.expects(:mail).once

    params = {id: donation.id, authenticity_token: token}
    post '/void', params, 'rack.session' => session

    assert last_response.redirect?
    assert_equal 'Donation voided', last_request.session[:flash][:notice]
    assert donation.reload.void
  end

  test "can't void void" do
    order_id = 1234
    donation = Donation.create!(shop: @shop, status: 'void', order_id: order_id, donation_amount: 10)

    mock_order_api_call(order_id)
    mock_shop_api_call

    Pony.expects(:mail).never

    params = {id: donation.id, authenticity_token: token}
    post '/void', params, 'rack.session' => session

    assert last_response.redirect?
    assert_equal 'Donation is void', last_request.session[:flash][:error]
    assert donation.reload.void
  end

  test "void thresholded doesn't email" do
    order_id = 1234
    donation = Donation.create!(shop: @shop, status: 'thresholded', order_id: order_id, donation_amount: 10)

    mock_order_api_call(order_id)
    mock_shop_api_call

    Pony.expects(:mail).never

    params = {id: donation.id, authenticity_token: token}
    post '/void', params, 'rack.session' => session

    assert last_response.redirect?
    assert_equal 'Donation voided', last_request.session[:flash][:notice]
    assert donation.reload.void
  end

  test "preview_email" do
    mock_shop_api_call

    get '/preview_email', {template: 'order {{ order.name }}'}, 'rack.session' => session

    assert last_response.ok?
    assert_equal "order #1001", JSON.parse(last_response.body)['email_body']
  end

  test "test_email" do
    charity = Charity.find_by(shop: @shop)

    mock_shop_api_call
    Pony.expects(:mail).with(has_entry(body: "hello #{charity.name}"))

    get '/test_email', {email_template: 'hello {{ charity.name }}'}, 'rack.session' => session
    assert last_response.ok?
  end

  test "test_html_email" do
    charity = Charity.find_by(shop: @shop)

    mock_shop_api_call
    Pony.expects(:mail).with(has_entry(html_body: "<html>hello #{charity.name}</html>"))

    get '/test_email', {email_template: '<html>hello {{ charity.name }}</html>'}, 'rack.session' => session
    assert last_response.ok?
  end

  test "test_void_email" do
    charity = Charity.find_by(shop: @shop)

    mock_shop_api_call
    Pony.expects(:mail).with(has_entry(body: "goodbye #{charity.name}"))

    get '/test_email', {void_email_template: 'goodbye {{ charity.name }}'}, 'rack.session' => session
    assert last_response.ok?
  end

  test "preview_pdf" do
    charity = Charity.find_by(shop: @shop)

    mock_shop_api_call

    params ={template: 'hello {{ charity.name }}', status: 'default', authenticity_token: token}
    post '/preview_pdf', params, 'rack.session' => session
    assert last_response.ok?

    text = PDF::Inspector::Text.analyze(last_response.body)
    assert_equal text.strings.join, "hello #{charity.name}"
  end

  test "preview_pdf (void)" do
    charity = Charity.find_by(shop: @shop)

    mock_shop_api_call

    params = {template: 'hello {{ charity.name }}', status: 'void', authenticity_token: token}
    post '/preview_pdf', params, 'rack.session' => session
    assert last_response.ok?

    text = PDF::Inspector::Text.analyze(last_response.body)
    assert_equal text.strings.join, "VOIDhello #{charity.name}"
  end

  test "export" do
    Donation.create!(shop: @shop, order_id: 1234, donation_amount: 10, created_at: Time.now - 5.days)
    Donation.create!(shop: @shop, order_id: 5678, donation_amount: 10)

    mock_shop_api_call
    mock_order_api_call('1234')
    mock_order_api_call('5678')

    params = {email_to: 'kevin@example.com', start_date: Time.now - 3.days, end_date: Time.now + 2.days, authenticity_token: token}
    post '/export', params, 'rack.session' => session

    assert last_response.redirect?

    mail = Mail::TestMailer.deliveries.last
    csv = mail.attachments[0].read

    refute_match "1234", csv
    assert_match "5678", csv
  end

  private

  def session
    {
      shopify: { shop: @shop, token: 'token' },
      csrf: token
    }
  end

  def token
    @token ||= Rack::Protection::AuthenticityToken.random_token
  end
end
