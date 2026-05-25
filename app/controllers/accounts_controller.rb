 class AccountsController < ApplicationController
  def index
    render json: { accounts: AccountSerializer.normalize_records(accounts) }
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
    account = Account.find(params[:id])
    if account.update(account_params)
      render json: AccountSerializer.normalize(account)
    else
      render json: { errors: account.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def destroy
    account = Account.find(params[:id])
    account.destroy
    head :no_content
  end

  private

  def account_params
    params.fetch(:account, {}).permit(:id, :name, :category, :assignee_id, :rating, :tags, :phone, :tollfree, :fax, :email, :website,
      shipping_address_attributes: [:id, :street1, :street2, :city, :state, :zipcode, :country],
      billing_address_attributes: [:id, :street1, :street2, :city, :state, :zipcode, :country]
    )
  end

  def accounts
    Account.all
  end
 end
