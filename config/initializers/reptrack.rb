Rails.application.config.to_prepare do
  # Now Practify.config is available and AppConfiguration is loaded
  Reptrack.config do |config|
    # Configure your Practify settings here
    # config.some_setting = "some value"
  end
end
