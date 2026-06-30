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
    def index
      render json: PostSerializer.normalize_records(@campaign_posts)
    end

    def create
      @campaign_post.user = current_user
      @campaign_post.media.attach(params[:media]) if create_params[:media].present?

      if @campaign_post.save
         @campaign_post.draft!
        render json: PostSerializer.new(@campaign_post).serializable_hash, status: :created
      else
        render json: { errors: @campaign_post.errors.full_messages }, status: :unprocessable_entity
      end
    end

    # PATCH/PUT /campaign/posts/:id — update a draft (content/kind/url, optional new media)
    def update
      new_media = params.dig(:campaign_post, :media)
      @campaign_post.media.attach(new_media) if new_media.present?

      if @campaign_post.update(update_params)
        render json: PostSerializer.new(@campaign_post).serializable_hash
      else
        render json: { errors: @campaign_post.errors.full_messages }, status: :unprocessable_entity
      end
    end

    def destroy
      @campaign_post.destroy
      head :no_content
    end

    private

    # CanCanCan builds @campaign_post from this on create.
    def create_params
      params.require(:campaign_post).permit(:content, :kind, :url, :media)
    end

    def update_params
      params.require(:campaign_post).permit(:content, :kind, :url)
    end
  end
end
