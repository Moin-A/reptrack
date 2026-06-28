module Campaign
  # Fans a post out to social accounts: creates one ready Publication per
  # account (idempotently) and enqueues each for publishing. Only the user's
  # own active accounts are eligible.
  class CreatesPublication
    def initialize(user)
      @user = user
    end

    def call(post:, social_account_ids:)
      accounts = SocialAccount.active.where(user: @user, id: social_account_ids)

      publications = accounts.map do |account|
        Publication.find_or_create_by!(post: post, social_account: account) do |publication|
          publication.status = "ready"
        end
      end

      publications.each { |publication| PublishPublicationJob.perform_later(publication.id) }
      publications
    end
  end
end
