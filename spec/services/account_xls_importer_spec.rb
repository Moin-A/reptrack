require 'rails_helper'
require 'tempfile'

RSpec.describe AccountXlsImporter do
  let(:xlsx_type) { "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet" }

  # Mimics params[:file] from the multipart upload the controller receives.
  let(:upload) { Rack::Test::UploadedFile.new(Rails.root.join("spec/fixtures/files/accounts.xlsx"), xlsx_type) }

  # The fixture rows are owned by "admin"; building the ability from that user
  # lets the importer authorize creating them.
  let(:current_user) { create(:user, name: "admin") }
  let(:importer) { described_class.new(upload, Ability.new(current_user)) }

  describe "#valid?" do
    context "when the file is a well-formed accounts workbook" do
      it "returns true with no errors" do
        expect(importer.valid?).to be true
        expect(importer.errors).to be_empty
      end
    end

    context "when the file does not have the expected headers" do
      let(:upload) { Rack::Test::UploadedFile.new(Rails.root.join("spec/fixtures/files/invalid.xlsx"), xlsx_type) }

      it "returns false and reports the error" do
        expect(importer.valid?).to be false
        expect(importer.errors).to include("Invalid file headers")
      end
    end

    context "when the file fails both content type and header validation" do
      let(:upload) { Rack::Test::UploadedFile.new(Rails.root.join("spec/fixtures/files/invalid.xlsx"), "text/plain") }

      it "returns false and reports both errors" do
        expect(importer.valid?).to be false
        expect(importer.errors).to include("File is not a valid XLS file", "Invalid file headers")
      end
    end
  end

  describe "#execute" do
    context "with a valid accounts workbook" do
      # the fixture rows reference the "admin" user by name (same record the
      # importer's ability is built from)
      let!(:admin) { current_user }

      it "creates an account for each data row" do
        expect { importer.execute }.to change(Account, :count).by(2)
      end
    end

    context "with an invalid file" do
      let(:upload) { Rack::Test::UploadedFile.new(Rails.root.join("spec/fixtures/files/invalid.xlsx"), "text/plain") }

      it "does nothing" do
        expect { importer.execute }.not_to change(Account, :count)
      end
    end
  end

  describe "#validate_file_name" do
    context "with a snake_case file name" do
      # accounts.xlsx -> base name "accounts" is valid snake_case
      it "is valid" do
        expect(importer.valid?).to be true
        expect(importer.errors).not_to include("Invalid file name, file must be in snakecase")
      end
    end

    context "with a non-snake_case file name" do
      # valid content/headers, but the file name "_accounts" is not snake_case
      let(:upload) { Rack::Test::UploadedFile.new(Rails.root.join("spec/fixtures/files/_accounts.xlsx"), xlsx_type) }

      it "reports an invalid file name" do
        expect(importer.valid?).to be false
        expect(importer.errors).to include("Invalid file name, file must be in snakecase")
      end
    end
  end

  # An uploaded workbook must not modify accounts the current user is not allowed
  # to update, even when a row targets that account's id directly. See
  # AccountsController#import and Ability.
  describe "authorization" do
    let(:owner)    { create(:user, name: "owner") }
    let(:intruder) { create(:user, name: "intruder") }

    # A private account owned by someone else, that the intruder must not touch.
    let!(:victim) do
      create(:account, name: "Victim Co", email: "victim@example.com",
                       access: "Private", user: owner, assignee_id: nil)
    end

    # Wraps real .xlsx bytes (as produced by the exporter) in the kind of upload
    # the controller receives.
    def upload_for(xlsx)
      file = Tempfile.new([ "accounts", ".xlsx" ])
      file.binmode
      file.write(xlsx)
      file.rewind
      Rack::Test::UploadedFile.new(file.path, xlsx_type, original_filename: "accounts.xlsx")
    end

    # A workbook for an account that has been deleted, so its row is a *new*
    # record on import while still carrying the original owner/assignee.
    def upload_recreating(account)
      xlsx = AccountXlsExporter.new([ account ]).to_xlsx
      account.destroy
      upload_for(xlsx)
    end

    describe "updating an existing account" do
      # A workbook whose single row targets the victim's id but carries a changed
      # name — i.e. what a malicious upload would look like.
      let(:upload) do
        victim.name = "Hacked Name"
        xlsx = AccountXlsExporter.new([ victim ]).to_xlsx
        victim.reload
        upload_for(xlsx)
      end

      it "refuses to update an account the user cannot access and rolls back" do
        importer = described_class.new(upload, Ability.new(intruder))

        importer.execute

        expect(importer.errors).to include(a_string_matching(/not authorized to update/i))
        expect(victim.reload.name).to eq("Victim Co")
      end

      it "lets the owner update their own account" do
        importer = described_class.new(upload, Ability.new(owner))

        importer.execute

        expect(importer.errors).to be_empty
        expect(victim.reload.name).to eq("Hacked Name")
      end
    end

    describe "creating a new account" do
      it "refuses to let a non-admin create an account owned by another user" do
        elsewhere = create(:account, name: "Owned Elsewhere", email: "elsewhere@example.com",
                                     access: "Private", user: owner, assignee_id: nil)
        importer = described_class.new(upload_recreating(elsewhere), Ability.new(intruder))

        expect { importer.execute }.not_to change(Account, :count)
        expect(importer.errors).to include(a_string_matching(/not authorized to create/i))
      end

      it "lets a user create an account owned by themselves" do
        mine = create(:account, name: "Mine", email: "mine@example.com",
                                access: "Private", user: intruder, assignee_id: nil)
        importer = described_class.new(upload_recreating(mine), Ability.new(intruder))

        expect { importer.execute }.to change(Account, :count).by(1)
        expect(importer.errors).to be_empty
      end
    end
  end
end
