# Connects social accounts via OmniAuth.
#
# Register the app on the provider's developer portal, then set the ENV vars
# (FACEBOOK_APP_ID / FACEBOOK_APP_SECRET). The callback URL configured on the
# provider must match: <host>/auth/facebook/callback
Rails.application.config.middleware.use OmniAuth::Builder do
  # Two modes, depending on how the Meta app is set up:
  # - Facebook Login for Business (config_id): the configuration on the Meta app
  #   defines the permissions (e.g. pages_show_list, pages_manage_posts).
  #   Set FACEBOOK_CONFIG_ID and `scope` is ignored.
  # - Consumer Facebook Login (scope): identity-only fallback for apps without
  #   a business-login configuration.
  facebook_options = {
    info_fields: "id,name",                    # no `email` → avoids the email permission (review prompt)
    callback_path: "/auth/facebook/callback"
  }
  if ENV["FACEBOOK_CONFIG_ID"].present?
    facebook_options[:authorize_params] = { config_id: ENV["FACEBOOK_CONFIG_ID"] }
  else
    facebook_options[:scope] = "public_profile"
  end

  provider :facebook, ENV["FACEBOOK_APP_ID"], ENV["FACEBOOK_APP_SECRET"], facebook_options
end

# DEV: allow a plain GET link to /auth/facebook so the SPA's Connect button can
# start the flow via a full-page navigation. In PRODUCTION switch to POST only
# and trigger it with a CSRF-protected form (omniauth-rails_csrf_protection),
# since a cross-site GET request phase is forgeable.
OmniAuth.config.allowed_request_methods = %i[get post]
OmniAuth.config.silence_get_warning = true
