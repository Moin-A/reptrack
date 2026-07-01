module Campaign
  # Resolves a SocialAccount to its platform adapter via platform_tag.
  # Register new platforms here.
  class MatchesPlatformApi
    PLATFORMS = [
      Platforms::Mastodon,
      Platforms::Test,
      Platforms::TestFailure,
      Platforms::TestSkipped
    ].freeze

    def match(social_account)
      klass = PLATFORMS.find { |platform| platform::TAG == social_account.platform_tag }
      raise "Unsupported platform: #{social_account.platform_tag.inspect}" if klass.nil?

      klass.new
    end
  end
end
