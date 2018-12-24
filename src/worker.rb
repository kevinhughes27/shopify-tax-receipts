require 'sidekiq'
require 'redis'
require_relative './app'

require_relative 'jobs/order_webhook_job'
