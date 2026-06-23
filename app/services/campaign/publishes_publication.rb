module Campaign
  # Publishes a single Publication to its social account's platform, owning the
  # ready -> wip -> published/skipped/failed transitions, plus bounded retries.
  class PublishesPublication
    MAX_ATTEMPTS = 3
    TERMINAL_STATUSES = %w[published skipped failed].freeze

    def initialize
      @matches_platform_api = MatchesPlatformApi.new
    end

    def publish(publication_id)
      publication = Publication.includes(:post, :social_account).find(publication_id)
      return if TERMINAL_STATUSES.include?(publication.status) # idempotent: never re-publish

      publication.update!(status: "wip", attempts: publication.attempts + 1, last_attempted_at: Time.current)
      apply_result(publication, attempt(publication))
    end

    private

    def attempt(publication)
      @matches_platform_api.match(publication.social_account).publish!(publication)
    rescue => e
      Platforms::Result.new(status: :failed, message: "Publish raised an error", error: e)
    end

    def apply_result(publication, result)
      case result.status
      when :published
        publication.update!(status: "published", remote_id: result.remote_id, url: result.url, published_at: Time.current)
      when :skipped
        publication.update!(status: "skipped")
      else
        record_failure(publication, result)
      end
    end

    def record_failure(publication, result)
      exhausted = publication.attempts >= MAX_ATTEMPTS
      publication.update!(
        status: (exhausted ? "failed" : "wip"),
        failures: publication.failures + [ failure_entry(result) ]
      )
      PublishPublicationJob.perform_later(publication.id) unless exhausted
    end

    def failure_entry(result)
      { "message" => result.message, "error" => result.error&.message, "at" => Time.current }
    end
  end
end
