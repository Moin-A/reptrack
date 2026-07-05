module Campaign
  # Connects (or reconnects) a social account for a user from submitted
  # credentials: persists them encrypted, validates against the platform where
  # an adapter supports it, and syncs label/active from the live result.
  # The controller stays thin: params in → Result out.
  class ConnectsSocialAccount
    # Outcome contract for the controller to render from.
    Result = Struct.new(:account, :metadata, :error, keyword_init: true) do
      def success? = error.nil?
    end

    def initialize(user, account)
      @user = user
      @account = account
    end

    # Persists the submitted credentials (when given), validates them via the
    # platform adapter, and always returns a Result.
    def call(params_hash = {})
      build_account(params_hash) unless params_hash.empty?

      validation = validate_credentials(@account)

      if validation[:ok]
        @account.update!(label: validation[:body]["name"].presence || @account.label)
        Result.new(account: @account, metadata: validation[:body])      # success + live metadata
      elsif validation[:unsupported]
        Result.new(account: @account)                                   # success, no validation available
      else
        @account.update!(active: false)
        Result.new(account: @account, error: validation[:message])      # failure — error set ⇒ success? == false
      end
    end

    private

    def build_account(params_hash)
      @account.assign_attributes(
        label: params_hash[:label].presence || @account.label.presence || params_hash[:platform_tag].capitalize,
        credentials: params_hash[:credentials],
        credentials_renewed_at: Time.current,
        active: true
      )
      @account.save!
    end

    # Adapter validation where available; platforms without an adapter or
    # without metadata support are reported as unsupported (not failures).
    def validate_credentials(account)
      adapter = Campaign::MatchesPlatformApi.new.match(account)
      result = adapter.fetch_metadata(account)
      result[:ok] || !result[:message].to_s.include?("does not support") ? result : result.merge(unsupported: true)
    rescue RuntimeError
      { ok: false, unsupported: true, message: "no adapter for #{account.platform_tag}" }
    end
  end
end
