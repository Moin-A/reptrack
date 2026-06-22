# One spreadsheet column: a header label and an accessor describing how to read
# its value from a record. The accessor is either a Symbol (a method called on
# the record) or a Proc (record -> value) for associations / nested records.
#
#   XlsColumn.new(header: "Name", accessor: :name)
#   XlsColumn.new(header: "User", accessor: ->(r) { r.user&.name })
XlsColumn = Struct.new(:header, :accessor, keyword_init: true) do
  def value_for(record)
    accessor.is_a?(Proc) ? accessor.call(record) : record.public_send(accessor)
  end
end
