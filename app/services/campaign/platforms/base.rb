module Campaign
  module Platforms
    # Interface every platform adapter implements. A subclass declares a TAG
    # (matched against SocialAccount#platform_tag) and optionally a
    # REQUIRED_CREDENTIALS constant, and implements #publish!.
    class Base
      def required_credentials
        self.class.const_defined?(:REQUIRED_CREDENTIALS, false) ? self.class::REQUIRED_CREDENTIALS : []
      end

      # Publishes the publication to the network; returns a Platforms::Result.
      def publish!(_publication)
        raise NotImplementedError, "#{self.class} must implement #publish!"
      end

      # Live metadata for the connected account (name, followers, …) fetched
      # with its stored credentials. Returns { ok:, body:/message: }.
      def fetch_metadata(_social_account)
        { ok: false, message: "#{self.class::TAG} does not support metadata" }
      end
    end
  end
end
