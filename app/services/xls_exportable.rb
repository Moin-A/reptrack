require "caxlsx"

# Shared .xlsx (Office Open XML) workbook builder.
#
# Including classes must implement:
#   records        - the collection to export
#   worksheet_name - the worksheet tab label
#   headers        - array of column header strings
#   row(record)    - array of cell values for one record
module XlsExportable
  def to_xlsx
    package = Axlsx::Package.new
    return if headers.blank? || records.blank?
    package.workbook.add_worksheet(name: worksheet_name) do |sheet|
      sheet.add_row(headers)
      records.each { |record| sheet.add_row(row(record)) }
    end
    package.to_stream.read
  end
end
