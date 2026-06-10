# Exports accounts as a SpreadsheetML (Excel) workbook.
class AccountXlsExporter
  include XlsExportable

  HEADERS = [
    "Id",
    "User",
    "Assigned To",
    "Name",
    "Email",
    "Phone",
    "Access",
    "Rating",
    "Category",
    "Website",
    "Date Created",
    "Date Updated",
    "Billing Street1",
    "Billing Street2",
    "Billing City",
    "Billing State",
    "Billing Zipcode",
    "Billing Country",
    "Shipping Street1",
    "Shipping Street2",
    "Shipping City",
    "Shipping State",
    "Shipping Zipcode",
    "Shipping Country"
  ].freeze

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
    HEADERS
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
