 class AccountsController < ApplicationController
  def index
    render json: { accounts: AccountSerializer.normalize_records(accounts) }
  end

  def create
    account = Account.new(accounts_params)
    if account.save
      render json: AccountSerializer.normalize(account), status: :created
    else
      render json: { errors: account.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def update
    account = Account.find(params[:id])
    if account.update(accounts_params)
      render json: AccountSerializer.normalize([ account ]).first
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

  def accounts_details_params
    params.fetch(:account_details, {}).permit(:name, :category, :assigned_to, :rating, :tags, :phone, :tollfree, :fax, :email, :website)
  end

  # "street1"=>"Bhoomkar chowk", "street2"=>"", "city"=>"Pune", "state"=>"Colorado", "zip"=>"41105", "country"=>""}, "billing_address"=>{"street1"=>"Bhoomkar chowk", "street2"=>"", "city"=>"Pune", "state"=>"Colorado", "zip"=>"41105", "country"=>""}, "controller"=>"accounts", "action"=>"create", "account"=>{}} permitted: false>

  def billing_address_params
    params.fetch(:billing_address, {}).permit(:street1, :street2, :city, :state, :zip, :country)
  end

  def shipping_address_params
    params.fetch(:shipping_address, {}).permit(:street1, :street2, :city, :state, :zip, :country)
  end

  def accounts
    Account.all
  end
 end
