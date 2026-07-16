class OpportunitiesController < ApplicationController
  load_and_authorize_resource

  def index
    # Ransack over the CanCan-scoped relation. A blank search is ignored by
    # ransack, so no guard is needed. `account_name_cont` searches through the
    # association, which Account allowlists via Ransackable.
    opportunities = @opportunities.ransack(
      name_or_stage_cont: params[:search],
      s: sort_expression
    ).result.includes(:account, :user, :assignee)

    render json: { opportunities: OpportunitySerializer.normalize_records(opportunities) }
  end

  def create
    @opportunity.user = current_user
    if @opportunity.save
      render json: { opportunity: OpportunitySerializer.normalize(@opportunity) }, status: :created
    else
      render json: { errors: @opportunity.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def update
    if @opportunity.update(opportunity_params)
      render json: { opportunity: OpportunitySerializer.normalize(@opportunity) }
    else
      render json: { errors: @opportunity.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def destroy
    @opportunity.destroy
    head :no_content
  end

  private

  def opportunity_params
    params.fetch(:opportunity, {}).permit(
      :name, :stage, :closes_on, :probability, :amount, :discount,
      :background_info, :access, :account_id, :assignee_id
    )
  end
end
