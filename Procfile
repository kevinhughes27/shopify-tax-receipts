web: bundle exec rackup config.ru -p $PORT
worker: bundle exec sidekiq -c 5 -r ./src/app.rb
release: bundle exec rake db:migrate
