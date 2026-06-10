require "builder"

# Shared SpreadsheetML (Excel) workbook builder, modeled after
# fat_free_crm's index.xls.builder templates.
#
# Including classes must implement:
#   records        - the collection to export
#   worksheet_name - the worksheet tab label
#   headers        - array of column header strings
#   row(record)    - array of cell values for one record
module XlsExportable
  def to_xls
    xml = Builder::XmlMarkup.new
    xml.instruct!
    xml.Workbook(
      "xmlns:x"    => "urn:schemas-microsoft-com:office:excel",
      "xmlns:ss"   => "urn:schemas-microsoft-com:office:spreadsheet",
      "xmlns:html" => "http://www.w3.org/TR/REC-html40",
      "xmlns"      => "urn:schemas-microsoft-com:office:spreadsheet",
      "xmlns:o"    => "urn:schemas-microsoft-com:office:office"
    ) do
      xml.Worksheet "ss:Name" => worksheet_name do
        xml.Table do
          header_row(xml)
          records.each do |record|
            data_row(xml, record)
          end
        end
      end
    end
    xml.target!
  end

  private

  def header_row(xml)
    xml.Row do
      headers.each do |head|
        xml.Cell do
          xml.Data head, "ss:Type" => "String"
        end
      end
    end
  end

  def data_row(xml, record)
    xml.Row do
      row(record).each do |value|
        xml.Cell do
          xml.Data value, "ss:Type" => (value.respond_to?(:abs) ? "Number" : "String")
        end
      end
    end
  end
end
