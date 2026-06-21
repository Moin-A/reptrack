class AccountsController < ApplicationController
  include ActionController::MimeResponds

  load_and_authorize_resource

  def index
    respond_to do |format|
      format.json { render json: { accounts: AccountSerializer.normalize_records(@accounts) } }
      format.xls do
        send_data AccountXlsExporter.new(@accounts).to_xls,
          filename: "accounts_#{Date.current}.xls",
          type: :xls,
          disposition: "attachment"
      end
    end
  end

  def import
    return render json: { error: "No file uploaded" }, status: :bad_request unless params[:file].present?
    export_service = AccountXlsImporter.new(params[:file])
    if export_service.valid?
      render json: { message: "Accounts imported successfully" }, status: :ok
    else
      render json: { message: export_service.errors }, status: :unprocessable_entity
    end
  end

  def create
    @account.update(create_account_params)
    if @account.save
      @account.user_ids = permitted_users_params[:permitted_users]
      render json: AccountSerializer.normalize(@account), status: :created
    else
      render json: { errors: @account.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def update
    if @account.update(account_params)
      render json: AccountSerializer.normalize(@account)
    else
      render json: { errors: @account.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def destroy
    @account.destroy
    head :no_content
  end

  private

  def account_params
    params.fetch(:account, {}).permit(:id, :name, :category, :assignee_id, :rating, :tags, :phone, :access, :tollfree, :fax, :email, :website,
      shipping_address_attributes: [ :id, :street1, :street2, :city, :state, :zipcode, :country ],
      billing_address_attributes: [ :id, :street1, :street2, :city, :state, :zipcode, :country ]
    )
  end

  def create_account_params
    account_params.except(:id)
  end

  def permitted_users_params
    params.permit(permitted_users: [])
  end

  def permitted_groups_params
    params.permit(permitted_groups: [])
  end

  def set_group
    if permitted_groups_params[:permitted_groups].present?
      @group = Group.find(permitted_groups_params[:permitted_groups].first)
    end
  end
end
