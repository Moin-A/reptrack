class AccountsController < ApplicationController
  load_and_authorize_resource

  def index
    render json: { accounts: AccountSerializer.normalize_records(@accounts) }
  end

  def create
    account = Account.new(account_params)
    if account.save
      render json: AccountSerializer.normalize(account), status: :created
    else
      render json: { errors: account.errors.full_messages }, status: :unprocessable_entity
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
    params.fetch(:account, {}).permit(:id, :name, :category, :assignee_id, :rating, :tags, :phone, :tollfree, :fax, :email, :website,
      shipping_address_attributes: [ :id, :street1, :street2, :city, :state, :zipcode, :country ],
      billing_address_attributes: [ :id, :street1, :street2, :city, :state, :zipcode, :country ]
    )
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
