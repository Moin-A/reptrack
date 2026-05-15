 class AccountsController < ApplicationController
  def index
    render json: { accounts: AccountSerializer.normalize_records(accounts) }
  end

  def create
    account = Account.new(accounts_params)
    if account.save
      render json: AccountSerializer.normalize([ account ]).first, status: :created
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

  def accounts_params
    params.fetch(:account, {}).permit(:name, :email, :phone, :rating, :access, :assigned_to)
  end

  def accounts
    Account.all
  end
 end
