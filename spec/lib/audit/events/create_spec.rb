require "rails_helper"

RSpec.describe Audit::Events::Create do
  let(:record) { build_stubbed(:task) }

  describe "#initialize" do
    it "initializes @record" do
      event = described_class.new(record)
      expect(event.instance_variable_get(:@record)).to eq(record)
    end

    it "defaults @in_after_callback to false" do
      event = described_class.new(record)
      expect(event.instance_variable_get(:@in_after_callback)).to be false
    end

    it "sets @in_after_callback when provided" do
      event = described_class.new(record, true)
      expect(event.instance_variable_get(:@in_after_callback)).to be true
    end
  end

  describe "#data" do
    before { Audit::Request.whodunnit = nil }
    after  { Audit::Request.whodunnit = nil }

    subject(:event) { described_class.new(record) }

    it "returns :item set to the record" do
      expect(event.data[:item]).to eq(record)
    end

    it "returns 'create' as the default event" do
      expect(event.data[:event]).to eq("create")
    end

    context "when the record has a custom audit_trail_event" do
      let(:record) { build_stubbed(:task, audit_trail_event: "import") }

      it "uses the record's audit_trail_event" do
        expect(event.data[:event]).to eq("import")
      end
    end

    context "when Audit::Request.whodunnit is set" do
      before { Audit::Request.whodunnit = "user:42" }

      it "includes the whodunnit value" do
        expect(event.data[:whodunnit]).to eq("user:42")
      end
    end

    context "when Audit::Request.whodunnit is a callable" do
      before { Audit::Request.whodunnit = -> { "lazy_user" } }

      it "calls the proc and returns the result" do
        expect(event.data[:whodunnit]).to eq("lazy_user")
      end
    end

    context "when Audit::Request.whodunnit is nil" do
      it "sets :whodunnit to nil" do
        expect(event.data[:whodunnit]).to be_nil
      end
    end

    context "created_at column" do
      context "when record responds to updated_at" do
        let(:timestamp) { Time.current }
        let(:record) { build_stubbed(:task, updated_at: timestamp) }

        it "includes :created_at in data" do
          expect(event.data).to have_key(:created_at)
        end

        it "sets :created_at to the record's updated_at" do
          expect(event.data[:created_at]).to eq(timestamp)
        end
      end

      context "when record does not respond to updated_at" do
        before { allow(record).to receive(:respond_to?).with(:updated_at).and_return(false) }

        it "does not include :created_at in data" do
          expect(event.data).not_to have_key(:created_at)
        end
      end
    end
  end
end
