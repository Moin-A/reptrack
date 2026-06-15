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

    def valid?
      validate_content_type
      validate_file_headers
      errors.empty?
    end

    private

    def headers
     Account.model_headers
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
      doc&.css("Row").first&.css("Data")&.map(&:text) || []
    end

    def parse_content
      # Logic to parse the content and populate @errors if needed
    end

    def import_accounts
      # Logic to import accounts from the parsed content
    end
end
