shop = Shop.create(name: 'apple.myshopify.com', token: 'token')
charity = Charity.create(shop: shop.name, name: 'Amnesty', charity_id: 12345)
