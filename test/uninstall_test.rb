require "test_helper"

class UninstallTest < ActiveSupport::TestCase

  def app
    SinatraApp
  end

  setup do
    @shop = "apple.myshopify.com"
    @noop_shop = "banana.myshopify.com"
  end

  test "uninstall" do
    webhook = load_fixture 'shop.json'
    SinatraApp.any_instance.expects(:verify_shopify_webhook).returns(true)

    assert_difference 'Shop.count', -1 do
      assert_difference 'Charity.count', -1 do
        assert_difference 'Product.count', -1 do
          post '/uninstall', webhook, 'HTTP_X_SHOPIFY_SHOP_DOMAIN' => @shop
        end
      end
    end
  end

  test "uninstall no products" do
    webhook = load_fixture 'shop.json'
    SinatraApp.any_instance.expects(:verify_shopify_webhook).returns(true)

    assert_difference 'Shop.count', -1 do
      assert_difference 'Charity.count', -1 do
        assert_no_difference 'Product.count' do
          post '/uninstall', webhook, 'HTTP_X_SHOPIFY_SHOP_DOMAIN' => @noop_shop
        end
      end
    end
  end
end
