# task :send_announcement do
#   Shop.find_each { |shop| send_announcement(shop) }
# end
#
# def send_announcement(shop)
#   puts "Sending announcement to shop: #{shop.name}"
#
#   api_session = ShopifyAPI::Session.new(shop.name, shop.token)
#   ShopifyAPI::Base.activate_session(api_session)
#
#   shopify_shop = ShopifyAPI::Shop.current
#
#   Pony.mail to: shopify_shop.email,
#             from: 'kevinhughes27@gmail.com',
#             subject: 'Shopify Tax Receipts Update',
#             body: announcement
# rescue => e
#   puts "Error emailing shop: #{shop.name} error: #{e}"
# end
#
# def announcement
#   @announcement ||= File.read('public/announcement.txt')
# end
