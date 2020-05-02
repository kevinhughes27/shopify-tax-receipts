web: bundle exec puma -C ./config/puma.rb -p $PORT

worker: bundle exec sidekiq -C ./config/sidekiq.yml -r ./src/app.rb

release: bundle exec rake db:migrate
