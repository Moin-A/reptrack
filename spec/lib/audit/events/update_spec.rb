require "rails_helper"

RSpec.describe Audit::Events::Update do
  let(:record) { build_stubbed(:task) }
  let(:default_kwargs) { { force: false, in_after_callback: true, is_touch: false } }

  describe "#initialize" do
    it "initializes @record and @in_after_callback" do
      event = described_class.new(record, **default_kwargs.merge(in_after_callback: false))
      expect(event.instance_variable_get(:@record)).to eq(record)
      expect(event.instance_variable_get(:@in_after_callback)).to be false
    end

    it "sets @force from the keyword argument" do
      event = described_class.new(record, **default_kwargs.merge(force: true))
      expect(event.instance_variable_get(:@force)).to be true
    end
  end

  describe "#data" do
    before { Audit::Request.whodunnit = nil }
    after  { Audit::Request.whodunnit = nil }

    subject(:event) { described_class.new(record, **default_kwargs) }

    it "returns :item set to the record" do
      expect(event.data[:item]).to eq(record)
    end

    it "returns 'update' as the default event" do
      expect(event.data[:event]).to eq("update")
    end

    context "when the record has a custom audit_trail_event" do
      let(:record) { build_stubbed(:task, audit_trail_event: "bulk_update") }

      it "uses the record's audit_trail_event" do
        expect(event.data[:event]).to eq("bulk_update")
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

    context "object column" do
      context "when record has an object column" do
        before do
          # Stubbing recordable_object for now — remove once the method is defined
          allow(event).to receive(:recordable_object).and_return({ "name" => "old" })
        end

        it "includes :object in data" do
          expect(event.data).to have_key(:object)
        end

        it "sets :object to the result of recordable_object" do
          expect(event.data[:object]).to eq({ "name" => "old" })
        end
      end

      context "when record does not have an object column" do
        before { allow(event).to receive(:record_object?).and_return(false) }

        it "does not include :object in data" do
          expect(event.data).not_to have_key(:object)
        end
      end
    end
  end
end
