Playbook
========

### Running Locally

(Note: see `shopify-sinatra-app`)

First you need a .env file that includes:

SHOPIFY_API_KEY=
SHOPIFY_SHARED_SECRET=
SECRET=
SIDEKIQ_USERNAME=
SIDEKIQ_PASSWORD=
DEVELOPMENT=1

Make sure the tunnel is started `forward 5000 shopify`
The development app is configured for https://shopify-kevinhughes27.fwd.wf

Then run `foreman start -m all=1,release=0 ` or `PORT=5000 foreman run web` if you need byebug

### Testing

To run a single test file:

```
bundle exec rake test TEST=test/app_test.rb
```

### Staging

```
git add remote staging https://git.heroku.com/taxreceipts-staging.git
git push staging <branch_name>:master -f
```

### Debug Production

Sinatra console on production:

```
heroku run bundle exec irb --app taxreceipts

require_relative 'src/app.rb'
```

Debug a shop

```
heroku run bundle exec rake debug_shop\[kevintest3.myshopify.com\] --app taxreceipts

$> starts irb with the shop activated for API use
```

Check webhooks for shop:

```
name = 'kevintest3.myshopify.com'
shop = Shop.find_by(name: name)

api_session = ShopifyAPI::Session.new(shop.name, shop.token)
ShopifyAPI::Base.activate_session(api_session)

ShopifyAPI::Webhook.all
```


Re-create the webhook (after checking using the above):

```
order_webhook = ShopifyAPI::Webhook.new({topic: 'orders/paid', address: 'https://taxreceipts.herokuapp.com/order.json', format: 'json'})
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

### Migrations locally

If you are backfilling and need encrypted shop tokens use:

```
foreman run bundle exec rake db:migrate
```
