require "test_helper"

class CharityTest < ActiveSupport::TestCase
  setup do
    @shop = "apple.myshopify.com"
    @charity = Charity.find_by(shop: @shop)
  end

  test "blank email_bcc" do
    @charity.email_bcc = ""
    assert @charity.save
  end

  test "valid email_bcc" do
    @charity.email_bcc = "joe@example.com"
    assert @charity.save
  end

  test "multiple email_bcc" do
    @charity.email_bcc = "joe@example.com, bob@example.com"
    assert @charity.save
  end

  test "invalid email_bcc" do
    @charity.email_bcc = "example.com"
    refute @charity.save
  end
end
