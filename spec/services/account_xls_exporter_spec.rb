require 'rails_helper'

RSpec.describe AccountXlsImporter do
  # Mimics params[:file] from the multipart upload the controller receives.
  let(:upload) { Rack::Test::UploadedFile.new(Rails.root.join("spec/fixtures/files/accounts.xls"), "application/vnd.ms-excel") }

  subject(:importer) { described_class.new(upload) }

  describe "#valid?" do
    context "when the file is a well-formed accounts workbook" do
      it "returns true with no errors" do
        expect(importer.valid?).to be true
        expect(importer.errors).to be_empty
      end
    end

    context "when the file is not a valid XLS workbook" do
      let(:upload) { Rack::Test::UploadedFile.new(Rails.root.join("spec/fixtures/files/invalid.xls"), "text/plain") }

      it "returns false and reports the error" do
        expect(importer.valid?).to be false
        expect(importer.errors).to include("File is not a valid XLS file", "Invalid file headers")
      end
    end
  end
end
