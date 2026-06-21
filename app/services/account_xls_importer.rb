# Imports accounts from a SpreadsheetML (Excel) workbook produced by
# AccountXlsExporter.
class AccountXlsImporter
    attr_accessor :content, :errors, :doc
    def initialize(content)
      @errors = []
      @content = content
      @doc = Nokogiri::XML(content)
      @content.rewind if @content.respond_to?(:rewind)
    end

    def execute
      parsed_rows.each_with_index do |parsed_row, index|
        params = row_params(parsed_row)
        account = model_class.find_or_initialize_by(id: params[:id])
        account.assign_attributes(params.except(:id, :date_created, :date_updated))
        errors << "failed to save account row#{index + 1}, #{account.errors.full_messages.join(", ")}" unless account.save
      end
    end

    def valid?
      validate_content_type
      validate_file_headers
      validate_file_name
      errors.empty?
    end

    private

    def headers
     Account.model_headers.map(&:downcase).map { |text| text.gsub(/\s/, "_") }
    end

    def to_hash(row_attributes)
      pairs = headers.zip(row_attributes)
      pairs.to_h.each_with_object({}) do |(key, value), hash|
        if key == "user"
          hash[:user_id] = User.find_by(name: value)&.id
        elsif key == "assigned_to"
          hash[:assignee_id] = User.find_by(name: value)&.id
        elsif key.match?(/\Abilling_/)
          hash[:billing_address_attributes] ||= {}
          hash[:billing_address_attributes][key.gsub("billing_", "").to_sym] = value
        elsif key.match?(/\Ashipping_/)
          hash[:shipping_address_attributes] ||= {}
          hash[:shipping_address_attributes][key.gsub("shipping_", "").to_sym] = value
        else
          hash[key.to_sym] = value
        end
      end
    end

    def validate_file_name
      unless @content.original_filename.match?(/\A[a-z]+_?\.xls\z/)
        errors << "Invalid file name, file must be in snakecase"
      end
    end

    def validate_content_type
      unless content.content_type == "application/vnd.ms-excel"
        errors << "File is not a valid XLS file"
      end
    end

    def validate_file_headers
       unless parsed_headers == headers
         errors << "Invalid file headers"
       end
    end

    def parsed_headers
      raw = doc&.css("Row")&.first&.css("Data")&.map(&:text) || []
      raw.map(&:downcase).map { |t| t.gsub(/\s/, "_") }
    end

    def parsed_rows
      doc&.css("Row")[1..]&.map do |row|
        row.css("Data").map(&:text)
      end || []
    end

    def row_params(parsed_row)
      to_hash(parsed_row)
    end

    def model_class_name
      content.original_filename.split(".").first.camelize
    end

    def model_class
      Object.const_get(model_class_name.singularize)
    end

    def import_accounts
      # Logic to import accounts from the parsed content
    end
end
