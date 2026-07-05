module Campaign
  # Handles the OAuth callback after a user connects a social account.
  # OmniAuth's middleware completes the handshake and populates
  # request.env["omniauth.auth"] before this controller runs.
  class OmniauthCallbacksController < ApplicationController
    # GET /auth/:provider/callback
    def create
      auth = request.env["omniauth.auth"]

      # This is a top-level browser redirect with no JWT, so we identify the user
      # via the signed `link_token` the SPA passed into the request phase
      # (preserved by OmniAuth as omniauth.params).
      user = user_from_link_token
      return redirect_to_frontend(error: "not_signed_in") unless user

      account = Campaign::SocialAccount.find_or_initialize_by(
        user: user,
        platform_tag: auth.provider # e.g. "facebook"
      )
      account.label = auth.info&.name.presence || auth.provider
      account.credentials = {
        "uid"           => auth.uid,
        "access_token"  => auth.credentials&.token,
        "refresh_token" => auth.credentials&.refresh_token,
        "expires_at"    => auth.credentials&.expires_at
      }.compact
      account.credentials_renewed_at = Time.current
      account.active = true
      account.save!

      redirect_to_frontend(connected: auth.provider)
    end

    # GET /auth/failure
    def failure
      redirect_to_frontend(error: params[:message].presence || "auth_failed")
    end

    private

    # Verify the signed token from the request phase → the connecting user.
    def user_from_link_token
      token = request.env.dig("omniauth.params", "link_token")
      return nil if token.blank?

      user_id = Rails.application.message_verifier(:oauth_link).verify(token, purpose: :oauth_link)
      User.find_by(id: user_id)
    rescue ActiveSupport::MessageVerifier::InvalidSignature
      nil
    end

    # Send the browser back to the SPA after the OAuth round-trip.
    def redirect_to_frontend(**query)
      base = ENV.fetch("FRONTEND_URL", "http://localhost:3000")
      redirect_to "#{base}/dashboard?#{query.to_query}", allow_other_host: true
    end
  end
end
