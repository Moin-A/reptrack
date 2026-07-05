# Exports accounts as an .xlsx (Office Open XML) workbook.
class AccountXlsExporter
  include XlsExportable

  def initialize(records)
    @records = records
    @base_class = records.first.class unless records.empty?
  end

  private

  def records
    @records
  end

  def worksheet_name
    @base_class.name
  end

  def headers
    @base_class&.model_headers
  end

  def row(record)
    @base_class&.xls_columns&.map { |col| col.value_for(record) }
  end
end
