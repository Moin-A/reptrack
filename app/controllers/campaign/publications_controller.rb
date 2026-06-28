module Campaign
  class PublicationsController < ApplicationController
    # POST /campaign/publications
    # Launches a post to the given social accounts.
    # params: post_id, social_account_ids: []
    def create
      post = Campaign::Post.find_by!(id: params[:post_id], user: current_user)

      publications = Campaign::CreatesPublication.new(current_user).call(
        post: post,
        social_account_ids: Array(params[:social_account_ids])
      )

      render json: { publications: publications.map { |publication| serialize(publication) } }, status: :created
    end

    private

    def serialize(publication)
      {
        id: publication.id,
        social_account_id: publication.social_account_id,
        status: publication.status
      }
    end
  end
end
