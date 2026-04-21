 require "active_support/core_ext/integer/time"

  # Staging mirrors production but with relaxed settings for debugging
  Rails.application.configure do
    config.enable_reloading = false
    config.eager_load = true
    config.consider_all_requests_local = true  # Show error pages (useful in staging)
    config.active_storage.service = :local
    config.force_ssl = true
    config.logger = ActiveSupport::Logger.new(STDOUT)
      .tap  { |logger| logger.formatter = ::Logger::Formatter.new }
      .then { |logger| ActiveSupport::TaggedLogging.new(logger) }
    config.log_tags = [ :request_id ]
    config.log_level = ENV.fetch("RAILS_LOG_LEVEL", "debug")  # More verbose than prod
    config.action_mailer.perform_caching = true
    config.i18n.fallbacks = true
    config.active_support.report_deprecations = true  # Surface warnings in staging
    config.active_record.dump_schema_after_migration = false
    config.action_mailer.default_url_options = { host: "staging.reptrack.co.in" }
    config.action_mailer.smtp_settings = {
    address:              ENV["SMTP_ADDRESS"],
    port:                 587,
    user_name:            ENV["SMTP_USER_NAME"],
    password:             ENV["SMTP_PASSWORD"],
    authentication:       :login,
    enable_starttls_auto: true
  }
  end
