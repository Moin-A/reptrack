class LeadsController < ApplicationController
  load_and_authorize_resource

  def index
    render json: { leads: LeadSerializer.normalize_records(Lead.all) }
  end

  def create
    @lead.assign_attributes(lead_params.except(:id))
    if @lead.save
      render json: LeadSerializer.normalize(@lead), status: :created
    else
      render json: { errors: @lead.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def update
    lead = Lead.find(params[:id])
    if lead.update(lead_params)
      render json: LeadSerializer.normalize(lead)
    else
      render json: { errors: lead.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def destroy
    lead = Lead.find(params[:id])
    lead.destroy
    head :no_content
  end

  private

  def lead_params
    params.fetch(:lead, {}).permit(:id,
      :first_name, :last_name, :email, :alt_email, :phone, :mobile,
      :title, :company, :source, :status, :referred_by,
      :blog, :linkedin, :facebook, :twitter,
      :rating, :do_not_call, :background_info, :access, :assignee_id
    )
  end
end
