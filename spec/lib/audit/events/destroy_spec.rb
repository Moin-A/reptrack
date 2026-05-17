require "rails_helper"

RSpec.describe Audit::Events::Destroy do
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

    it "returns 'destroy' as the event" do
      expect(event.data[:event]).to eq("destroy")
    end

    it "includes :object set to the record's attributes" do
      expect(event.data[:object]).to eq(record.attributes)
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
  end
end
