module Campaign
  class PostsController < ApplicationController
    load_and_authorize_resource class: "Campaign::Post", instance_name: :campaign_post

    # POST /campaign/posts
    # Creates a post owned by the current user, optionally with an uploaded
    # media file attached. The user composes a post here, then launches it to
    # social accounts via PublicationsController.
    #
    # params: campaign_post: { content, kind (post|ad), url (optional link) },
    #         file (uploaded media)
    def create
      @campaign_post.user = current_user
      @campaign_post.media.attach(params[:media]) if create_params[:media].present?

      if @campaign_post.save
        render json: serialize(@campaign_post), status: :created
      else
        render json: { errors: @campaign_post.errors.full_messages }, status: :unprocessable_entity
      end
    end

    private

    # CanCanCan builds @campaign_post from this on create.
    def create_params
      params.require(:campaign_post).permit(:content, :kind, :url, :media)
    end

    def serialize(post)
      {
        id: post.id,
        kind: post.kind,
        content: post.content,
        url: post.url,
        media: post.media.map { |attachment| { id: attachment.id, filename: attachment.filename.to_s } }
      }
    end
  end
end
