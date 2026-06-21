require 'rails_helper'

RSpec.describe AccountXlsImporter do
  # Mimics params[:file] from the multipart upload the controller receives.
  let(:upload) { Rack::Test::UploadedFile.new(Rails.root.join("spec/fixtures/files/accounts.xls"), "application/vnd.ms-excel") }

  let(:importer) { described_class.new(upload) }

  describe "#valid?" do
    context "when the file is a well-formed accounts workbook" do
      it "returns true with no errors" do
        expect(importer.valid?).to be true
        expect(importer.errors).to be_empty
      end
    end

    context "when the file does not have the expected headers" do
      let(:upload) { Rack::Test::UploadedFile.new(Rails.root.join("spec/fixtures/files/invalid.xls"), "application/vnd.ms-excel") }

      it "returns false and reports the error" do
        expect(importer.valid?).to be false
        expect(importer.errors).to include("Invalid file headers")
      end
    end

    context "when the file fails both content type and header validation" do
      let(:upload) { Rack::Test::UploadedFile.new(Rails.root.join("spec/fixtures/files/invalid.xls"), "text/plain") }

      it "returns false and reports both errors" do
        expect(importer.valid?).to be false
        expect(importer.errors).to include("File is not a valid XLS file", "Invalid file headers")
      end
    end
  end

  describe "#execute" do
    context "with a valid accounts workbook" do
      # the fixture rows reference the "admin" user by name
      let!(:admin) { create(:user, name: "admin") }

      it "creates an account for each data row" do
        expect { importer.execute }.to change(Account, :count).by(2)
      end
    end

    context "with an invalid file" do
      let(:upload) { Rack::Test::UploadedFile.new(Rails.root.join("spec/fixtures/files/invalid.xls"), "text/plain") }

      it "does nothing" do
        expect { importer.execute }.not_to change(Account, :count)
      end
    end
  end

  describe "#validate_file_name" do
    context "with a snake_case file name" do
      # accounts.xls -> base name "accounts" is valid snake_case
      it "is valid" do
        expect(importer.valid?).to be true
        expect(importer.errors).not_to include("Invalid file name, file must be in snakecase")
      end
    end

    context "with a non-snake_case file name" do
      # valid content/headers, but the file name "_accounts" is not snake_case
      let(:upload) { Rack::Test::UploadedFile.new(Rails.root.join("spec/fixtures/files/_accounts.xls"), "application/vnd.ms-excel") }

      it "reports an invalid file name" do
        expect(importer.valid?).to be false
        expect(importer.errors).to include("Invalid file name, file must be in snakecase")
      end
    end
  end
end
