require 'sidekiq'

redis_url = if ENV['DEVELOPMENT']
  'redis://localhost:6379'
else
  ENV['REDIS_URL']
end

Sidekiq.configure_client do |config|
  config.redis = { url: redis_url }
end

Sidekiq.configure_server do |config|
  config.redis = { url: redis_url }
end
