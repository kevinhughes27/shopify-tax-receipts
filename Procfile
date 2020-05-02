web: bundle exec rackup config.ru -p $PORT

worker: bundle exec sidekiq -C ./config/sidekiq.yml -r ./src/app.rb

release: bundle exec rake db:migrate
