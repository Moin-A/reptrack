require_relative "boot"

require "rails/all"
require_relative "../lib/reptrack"
require_relative "../lib/reptrack/permission"
require_relative "../app/middleware/hello_middleware"
require_relative "../lib/audit/audit_trail"
# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Reptrack
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 7.2

    # Please, add to the `ignore` list any other `lib` subdirectories that do
    # not contain `.rb` files, or that should not be reloaded or eager loaded.
    # Common ones are `templates`, `generators`, or `middleware`, for example.
    # permission.rb is required at boot (it patches ActiveRecord::Base), so it
    # must stay out of the autoloader's hands.
    config.autoload_lib(ignore: %w[assets tasks reptrack/permission.rb])
    config.autoload_paths << Rails.root.join("app/serializers/concerns")

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    # config.time_zone = "Central Time (US & Canada)"
    # config.eager_load_paths << Rails.root.join("extras")

    # Full middleware stack: this app serves both the JSON API (controllers
    # inheriting ActionController::API) and Rails-rendered pages such as
    # billing/checkout, which need views, assets and sessions.
    #
    # Cookies and the session store are part of the default stack now, so they
    # are NOT re-registered here — doing so would insert them twice.
    config.api_only = false
    config.session_store :cookie_store, key: "_reptrack_session"

    config.middleware.use HelloMiddleware
  end
end
