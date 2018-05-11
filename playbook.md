Playbook
========

Sinatra console on production:

```
heroku run bundle exec irb --app taxreceipts

require_relative 'src/app.rb'
```

Check webhook for shop:

```
name = 'kevintest3.myshopify.com'
shop = Shop.find_by(name: name)

api_session = ShopifyAPI::Session.new(shop.name, shop.token)
ShopifyAPI::Base.activate_session(api_session)

ShopifyAPI::Webhook.all
```


Re-create the webhook (after checking using the above):

```
order_webhook = ShopifyAPI::Webhook.new({topic: 'orders/create', address: 'https://taxreceipts.herokuapp.com/order.json', format: 'json'})
order_webhook.save
```

List products setup for a shop:

```
products = Product.where(shop: 'kevintest3.myshopify.com').pluck(:id)
```

Parsing product_ids from order json:

```
require 'json'
file = File.read('order.json')
json = JSON.parse(file)
ids = json['order']['line_items'].map{ |l| l['product_id'] }
```
