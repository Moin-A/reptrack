# Exports accounts as a SpreadsheetML (Excel) workbook.
class AccountXlsExporter
  include XlsExportable

  def initialize(accounts)
    @accounts = accounts
  end

  private

  def records
    @accounts
  end

  def worksheet_name
    "Accounts"
  end

  def headers
    Account.model_headers
  end

  def row(account)
    billing  = account.billing_address
    shipping = account.shipping_address

    [
      account.id,
      account.user.try(:name),
      account.assignee.try(:name),
      account.name,
      account.email,
      account.phone,
      account.access,
      account.rating,
      account.category,
      account.website,
      account.created_at,
      account.updated_at,
      billing.try(:street1),
      billing.try(:street2),
      billing.try(:city),
      billing.try(:state),
      billing.try(:zipcode),
      billing.try(:country),
      shipping.try(:street1),
      shipping.try(:street2),
      shipping.try(:city),
      shipping.try(:state),
      shipping.try(:zipcode),
      shipping.try(:country)
    ]
  end
end
