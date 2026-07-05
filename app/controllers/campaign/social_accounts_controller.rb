module Campaign
  class SocialAccountsController < ApplicationController
    # GET /campaign/social_accounts — the current user's connected accounts.
    # Credentials are never exposed.
    def index
      accounts = Campaign::SocialAccount.where(user: current_user)
      render json: SocialAccountsSerializer.normalize_records(accounts)
    end

    # GET /campaign/social_accounts/connect_token
    # A short-lived signed token carrying the user's id through the OAuth `state`
    # round-trip — the callback is a plain browser redirect with no JWT, so this
    # is how it learns who is connecting. Authenticated via the normal API auth.
    def connect_token
      token = Rails.application.message_verifier(:oauth_link).generate(
        current_user.id, expires_in: 10.minutes, purpose: :oauth_link
      )
      render json: { token: token }
    end

    # POST /campaign/social_accounts — connect an account from the credentials
    # form (per-platform fields, e.g. facebook: page_id + access_token). The
    # credentials are stored encrypted (see SocialAccount#encrypts) and, where
    # the platform adapter supports it, validated by fetching live metadata.
    # params: platform_tag, label, credentials: { ... }
    def create
      account = Campaign::SocialAccount.find_or_initialize_by(user: current_user, platform_tag: params[:platform_tag])
      result = Campaign::ConnectsSocialAccount.new(current_user, account).call(
        platform_tag: params[:platform_tag],
        label: params[:label],
        credentials: credentials_params
      )

      if result.success?
        render json: SocialAccountsSerializer.normalize(account).merge(metadata: result.metadata), status: :created
      else
        render json: { errors: [ result.error ] }.merge(SocialAccountsSerializer.normalize(account)), status: :unprocessable_entity
      end
    end

    # POST /campaign/social_accounts/:id/refresh
    # Validates the stored credentials by fetching live metadata from the
    # platform (no login flow needed) and syncs label/active from the result.
    def refresh
      account = Campaign::SocialAccount.find_by!(id: params[:id], user: current_user)
      result = Campaign::MatchesPlatformApi.new.match(account).fetch_metadata(account)

      if result[:ok]
        account.update!(label: result[:body]["name"].presence || account.label, active: true)
        render json: SocialAccountsSerializer.normalize(account).merge(metadata: result[:body])
      else
        account.update!(active: false)
        render json: { errors: [ result[:message] ] }.merge(SocialAccountsSerializer.normalize(account)), status: :unprocessable_entity
      end
    end

    private

    # Arbitrary per-platform keys (page_id, access_token, base_url, …) — scoped
    # to the credentials hash, values coerced to strings, stored encrypted.
    def credentials_params
      params.require(:credentials).permit!.to_h.transform_values(&:to_s)
    end
  end
end
