def seed_db
  Shop.delete_all
  Charity.delete_all
  Product.delete_all
  Donation.delete_all

  apple = Shop.create!(name: 'apple.myshopify.com', token: 'token')
  Charity.create!(shop: apple.name, name: 'Amnesty', charity_id: 12345)
  Product.create(shop: apple.name, product_id: 632910392)

  banana = Shop.create!(name: 'banana.myshopify.com', token: 'token')
  Charity.create(shop: banana.name, name: 'Amnesty', charity_id: 56789)
end
