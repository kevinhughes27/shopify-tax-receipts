require 'irb'

# usage:
# heroku run bundle exec rake debug_shop\[kevintest3.myshopify.com\]

task :debug_shop, [:shop] do |t, args|
  shop = Shop.find_by(name: args[:shop])
  api_session = ShopifyAPI::Session.new(domain: shop.name, token: shop.token, api_version: API_VERSION)
  ShopifyAPI::Base.activate_session(api_session)

  ARGV.clear # otherwise all script parameters get passed to IRB
  IRB.start
end
