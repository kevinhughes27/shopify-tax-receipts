require './src/app'
require 'sidekiq'
require 'sidekiq/web'

map '/' do
  run SinatraApp
end

map '/sidekiq' do
  use Rack::Auth::Basic, "Protected Area" do |username, password|
    # Protect against timing attacks:
    # - See https://codahale.com/a-lesson-in-timing-attacks/
    # - See https://thisdata.com/blog/timing-attacks-against-string-comparison/
    # - Use & (do not use &&) so that it doesn't short circuit.
    # - Use digests to stop length information leaking
    Rack::Utils.secure_compare(::Digest::SHA256.hexdigest(username), ::Digest::SHA256.hexdigest(ENV["SIDEKIQ_USERNAME"])) &
      Rack::Utils.secure_compare(::Digest::SHA256.hexdigest(password), ::Digest::SHA256.hexdigest(ENV["SIDEKIQ_PASSWORD"]))
  end

  use Rack::Session::Cookie, secret: ENV["SECRET"], same_site: true, max_age: 86400

  run Sidekiq::Web
end
