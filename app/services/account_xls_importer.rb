require "roo"

# Imports accounts from an .xlsx workbook produced by AccountXlsExporter.
class AccountXlsImporter
    attr_accessor :content, :errors, :spreadsheet, :ability
    def initialize(content, ability)
      @errors = []
      @content = content
      @ability = ability
      @spreadsheet = open_spreadsheet
    end

    # Imports every data row inside a single transaction: if any row is
    # unauthorized or fails to save, the whole import is rolled back and the
    # reasons are collected in #errors.
    def execute
      ActiveRecord::Base.transaction do
        parsed_rows.each_with_index do |parsed_row, index|
          params = row_params(parsed_row)
          account = model_class.find_or_initialize_by(id: params[:id])

          # Existing record: authorize against its current persisted state,
          # before applying the spreadsheet, so a row can't grant itself access
          # by overwriting user_id/assignee_id.
          next if account.persisted? && !can_manage_account?(account, index)

          build_record(account, params)

          # New record: authorize after the row is applied, so the resulting
          # owner/assignee/access is what's checked — a non-admin may only create
          # accounts owned by or assigned to themselves (or public ones).
          next if account.new_record? && !can_manage_account?(account, index)

          errors << "failed to save account row#{index + 1}, #{account.errors.full_messages.join(", ")}" unless account.save
        end

        raise ActiveRecord::Rollback if errors.any?
      end
    end

    def valid?
      validate_content_type
      validate_file_headers
      validate_file_name
      errors.empty?
    end

    private

    # Opens the upload as an .xlsx workbook; nil when the file can't be parsed.
    def open_spreadsheet
      Roo::Spreadsheet.open(content.path, extension: :xlsx)
    rescue StandardError
      nil
    end

    # Authorizes the row's account for the current user, recording an error when
    # denied. A persisted record is checked for :update, a new one for :create.
    def can_manage_account?(account, index)
      action = account.persisted? ? :update : :create
      return true if ability.can?(action, account)

      errors << "row #{index + 1}: not authorized to #{action} account #{account.id}"
      false
    end

    # Applies a spreadsheet row's values to the account: scalar attributes plus
    # the nested billing/shipping addresses.
    def build_record(account, params)
      account.assign_attributes(scalar_params(params))
      apply_address(account, :billing_address, params[:billing_address_attributes])
      apply_address(account, :shipping_address, params[:shipping_address_attributes])
    end

    # Account's own attributes only; id, timestamps and the nested address
    # hashes are handled separately.
    def scalar_params(params)
      params.except(:id, :date_created, :date_updated,
                    :billing_address_attributes, :shipping_address_attributes)
    end

    # Upsert the address when the XLS row carries values, or remove the
    # existing one when those columns are blank. Updating in place avoids the
    # has_one "replace" path that nullifies the old record's foreign key.
    def apply_address(account, association, attrs)
      existing = account.public_send(association)
      if attrs && attrs.values.any?(&:present?)
        existing ? existing.assign_attributes(attrs) : account.public_send("build_#{association}", attrs)
      elsif existing
        existing.mark_for_destruction
      end
    end

    def headers
     Account.model_headers.map(&:downcase).map { |text| text.gsub(/\s/, "_") }
    end

    def to_hash(row_attributes)
      pairs = headers.zip(row_attributes)
      pairs.to_h.each_with_object(Hash.new { |h, k| h[k] = {} }) do |(key, value), hash|
        if key == "user"
          hash[:user_id] = User.find_by(name: value)&.id
        elsif key == "assigned_to"
          hash[:assignee_id] = User.find_by(name: value)&.id
        elsif key.match?(/\Abilling_/)
          hash[:billing_address_attributes][key.gsub("billing_", "").to_sym] = value
        elsif key.match?(/\Ashipping_/)
          hash[:shipping_address_attributes][key.gsub("shipping_", "").to_sym] = value
        else
          hash[key.to_sym] = value
        end
      end
    end

    def validate_file_name
      unless content.original_filename.match?(/\A[a-z]+(_[a-z]+)*\.(xlsx|xls)\z/)
        errors << "Invalid file name, file must be in snakecase"
      end
    end

    def validate_content_type
      unless content.content_type == "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
        errors << "File is not a valid XLS file"
      end
    end

    def validate_file_headers
       unless parsed_headers == headers
         errors << "Invalid file headers"
       end
    end

    def parsed_headers
      raw = spreadsheet&.row(1) || []
      raw.map { |t| t.to_s.downcase.gsub(/\s/, "_") }
    end

    def parsed_rows
      return [] unless spreadsheet

      (2..spreadsheet.last_row).map { |i| spreadsheet.row(i) }
    end

    def row_params(parsed_row)
      to_hash(parsed_row)
    end

    def model_class_name
      content.original_filename[/\A[a-z]+/]
    end

    def model_class
      model_class_name.classify.constantize
    end
end
