require 'rails_helper'

RSpec.describe AccountXlsExporter do
  describe "#to_xlsx" do
    it "generates an .xlsx file" do
      account = create(:account, name: "Acme Corp", email: "info@acme.com")

      output = described_class.new([ account ]).to_xlsx

      expect(output.byteslice(0, 2)).to eq("PK") # .xlsx files are ZIP archives
    end
  end
end
