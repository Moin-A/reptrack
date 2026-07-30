source "https://rubygems.org"

# Bundle edge Rails instead: gem "rails", github: "rails/rails", branch: "main"
gem "rails", "~> 7.2.3"
# Use postgresql as the database for Active Record
gem "pg", "~> 1.1"
# Use the Puma web server [https://github.com/puma/puma]
gem "puma", ">= 5.0"
# Build JSON APIs with ease [https://github.com/rails/jbuilder]
# gem "jbuilder"
# Use Redis adapter to run Action Cable in production
# gem "redis", ">= 4.0.1"

# Use Kredis to get higher-level data types in Redis [https://github.com/rails/kredis]
# gem "kredis"

# Use Active Model has_secure_password [https://guides.rubyonrails.org/active_model_basics.html#securepassword]
# gem "bcrypt", "~> 3.1.7"

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem "tzinfo-data", platforms: %i[ mswin mswin64 mingw x64_mingw jruby ]
gem "ros-apartment", require: "apartment"
# Reduces boot times through caching; required in config/boot.rb
gem "bootsnap", require: false
gem "devise"
gem "devise-jwt"

# Use Active Storage variants [https://guides.rubyonrails.org/active_storage_overview.html#transforming-images]
# gem "image_processing", "~> 1.2"

# Use Rack CORS for handling Cross-Origin Resource Sharing (CORS), making cross-origin Ajax possible
gem "rack-cors"
gem "jsonapi-serializer"
# Real .xlsx export (caxlsx) and import parsing (roo)
gem "caxlsx"
gem "roo"
# Object-based searching / filtering for API query params
gem "ransack"

group :development do
  gem "bullet"
end

group :development, :test do
  # See https://guides.rubyonrails.org/debugging_rails_applications.html#debugging-with-the-debug-gem
  gem "debug", platforms: %i[ mri mswin mswin64 mingw x64_mingw ], require: "debug/prelude"
  gem "pry-rails"

  # Static analysis for security vulnerabilities [https://brakemanscanner.org/]
  gem "brakeman", require: false

  # Omakase Ruby styling [https://github.com/rails/rubocop-rails-omakase/]
  gem "rubocop-rails-omakase", require: false

  gem "rspec-rails"
  gem "factory_bot_rails"
end

gem "cancancan"
gem "jwt", "~> 3.1"

gem "faker", "~> 3.6"
gem "pagy"
gem "sidekiq", "~> 7.0"
gem "sidekiq-failures"

gem "omniauth-facebook", "~> 10.0"

gem "omniauth-rails_csrf_protection", "~> 2.0"

gem "dotenv-rails", "~> 3.2", groups: [ :development, :test ]
