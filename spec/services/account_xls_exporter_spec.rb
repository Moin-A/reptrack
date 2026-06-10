require 'rails_helper'

RSpec.describe AccountXlsExporter do
  describe "#to_xls" do
    let(:account) do
      create(:account,
        name: "Acme Corp",
        email: "info@acme.com",
        phone: "555-0100",
        access: "Public",
        rating: 3,
        category: "Vendor",
        website: "https://acme.example.com")
    end

    def export(accounts)
      described_class.new(accounts).to_xls
    end

    it "produces a SpreadsheetML workbook" do
      xls = export([ account ])
      doc = Nokogiri::XML(xls)
      expect(doc.errors).to be_empty
      expect(doc.root.name).to eq("Workbook")
      expect(doc.root.namespaces.values).to include("urn:schemas-microsoft-com:office:spreadsheet")
    end

    it "includes a header row with the account columns" do
      xls = export([ account ])
      expect(xls).to include("Id", "Name", "Email", "Phone", "Category", "Rating", "Access", "Website")
    end

    it "includes the account values" do
      xls = export([ account ])
      expect(xls).to include("Acme Corp", "info@acme.com", "555-0100", "Vendor", "https://acme.example.com")
    end

    it "includes the billing address" do
      account.create_billing_address!(street1: "1 Main St", city: "Springfield", state: "IL", zipcode: "62701", country: "USA")
      xls = export([ account.reload ])
      expect(xls).to include("1 Main St", "Springfield", "62701")
    end

    it "marks numeric values as Number cells" do
      xls = export([ account ])
      expect(xls).to include(%(ss:Type="Number"))
    end

    it "handles accounts without addresses or associated users" do
      expect { export([ account ]) }.not_to raise_error
    end

    it "produces an empty table when there are no accounts" do
      doc = Nokogiri::XML(export([]))
      expect(doc.root.name).to eq("Workbook")
    end
  end
end
