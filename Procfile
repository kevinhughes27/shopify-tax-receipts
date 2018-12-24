web: bundle exec rackup config.ru -p $PORT
worker: bundle exec sidekiq -r ./src/worker.rb
release: bundle exec rake db:migrate
