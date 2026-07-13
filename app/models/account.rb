class Account < ApplicationRecord
   include Ransackable
   has_one :billing_address, -> { where(address_type: "billing") }, as: :addressable, class_name: "Address"
   has_one :shipping_address, -> { where(address_type: "shipping") }, as: :addressable, class_name: "Address"
   has_many :addresses, as: :addressable, class_name: "Address"
   has_many :contacts, class_name: "Contact"
   has_many :opportunities


   accepts_nested_attributes_for :shipping_address, allow_destroy: true
   accepts_nested_attributes_for :billing_address, allow_destroy: true
   validates :email, format: { with: /\A[^\s@]+@[^\s@]+\z/, message: "the email format is not valid", allow_blank: true }
   validates :name, presence: true
   attribute :access, :string, default: "Private"
   belongs_to :user, optional: true
   belongs_to :assignee, class_name: "User", foreign_key: "assignee_id", optional: true
   belongs_to :user, class_name: "User", foreign_key: "user_id", optional: true

   with_permission

   # Resolves the account for a lead being converted. An account is the one
   # entity in the conversion that may already exist (many leads share a
   # company), so it is *selected* when an id is given and *created* otherwise.
   # A new account inherits the lead's contact details — `email` is required by
   # the format validation above, and the lead is the only source for it.
   def self.create_or_select_for(lead, params = {}, assignee_id: nil)
     if params[:id].present?
      account = Account.find_by(id: params[:id])
      return account if account
     end

     account = Account.new(params)
     if account.access != "Lead" || lead.nil?
       account.save!
     else
       account.save_with_model_permissions(lead)
     end
     account
   end


   # Ordered XLS schema: each column is a header label plus an accessor for its
   # value (a Symbol method name, or a Proc for associations / nested records).
   # Single source of truth for the export and the header row the importer checks.
   def self.xls_columns
     [
       col("Id", :id),
       col("Name", :name),
       col("Rating", :rating),
       col("Email", :email),
       col("Phone", :phone),
       col("Access", :access),
       col("Category", :category),
       col("Website", :website),
       col("User", ->(a) { a.user&.name }),
       col("Assigned To", ->(a) { a.assignee&.name }),
       col("Date Created", :created_at),
       col("Date Updated", :updated_at),
       *address_cols("Billing", :billing_address),
       *address_cols("Shipping", :shipping_address)
     ].freeze
   end

   # Header labels, derived from the schema so they can never drift from values.
   def self.model_headers
     xls_columns.map(&:header)
   end

   private_class_method def self.col(header, accessor)
     XlsColumn.new(header: header, accessor: accessor)
   end

   # address col is wrapper of col to give more customizability to address fields
   private_class_method def self.address_cols(prefix, association)
     %i[street1 street2 city state zipcode country].map do |field|
       col("#{prefix} #{field.to_s.capitalize}", ->(a) { a.public_send(association)&.public_send(field) })
     end
   end
end
