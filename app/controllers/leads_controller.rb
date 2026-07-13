class LeadsController < ApplicationController
  load_and_authorize_resource

  def index
    # Ransack over the CanCan-scoped relation (was Lead.all — which bypassed
    # authorization scoping). Lead has no `name` column, so the "name" sort
    # maps to first/last name.
    leads = @leads.ransack(
      first_name_or_last_name_or_company_or_email_cont: params[:search],
      s: sort_expression(overrides: { "name" => [ "first_name asc", "last_name asc" ] })
    ).result

    render json: { leads: LeadSerializer.normalize_records(leads) }
  end

  def create
    if @lead.save
      render json: { lead: LeadSerializer.normalize(@lead) }, status: :created
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

  def convert
    @account, @opportunity, @contact = @lead.promote(convert_params)

    render json: {
        lead:        LeadSerializer.normalize(@lead),
        account:     AccountSerializer.normalize(@account),
        contact:     ContactSerializer.normalize(@contact),
        opportunity: (OpportunitySerializer.normalize(@opportunity) if @opportunity&.persisted?)
      }, status: :ok
    rescue ActiveRecord::RecordInvalid => e
      render json: {
        errors:    e.record.errors.full_messages,
        failed_on: e.record.class.name.underscore
      }, status: :unprocessable_entity
  end

  private

  def lead_params
    params.fetch(:lead, {}).permit(:id,
      :first_name, :last_name, :email, :alt_email, :phone, :mobile,
      :title, :company, :source, :status, :referred_by,
      :blog, :linkedin, :facebook, :twitter,
      :rating, :do_not_call, :background_info, :access, :assignee_id,
      business_address_attributes: [ :street1, :street2, :city, :state, :zipcode, :country ],
    )
  end

  # Nested under :lead like the other actions in this controller (and like Rails
  # param wrapping). Describes the records to build *from* the lead being converted.
  def convert_params
    params.fetch(:lead, {}).permit(
      :access,
      :assignee_id,
      account:     [ :id, :name, :email ],
      opportunity: [ :name, :stage, :closes_on, :probability, :amount, :discount ]
    )
  end
end
