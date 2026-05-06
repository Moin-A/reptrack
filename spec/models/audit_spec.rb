require 'rails_helper'

RSpec.describe Audit::AuditTrail, type: :model do
  let(:valid_attributes) {
    skip("Add a hash of attributes valid for your model")
  }

  it "succeeds when has_paper_trail is called for the first time" do
    klass = Class.new(ApplicationRecord)
    expect { klass.has_paper_trail }.not_to raise_error
  end

  it "raises an error if has_paper_trail is called more than once" do
    klass = Class.new(ApplicationRecord) do
      has_paper_trail
    end

    expect { klass.has_paper_trail }.to raise_error(Audit::AuditTrail::Error, "has_paper_trail must be called only once")
  end

  it "creates a version when a task is updated" do
    task = Task.create! valid_attributes
    expect {
      task.update!(name: "updated name")
    }.to change(AuditVersion, :count).by(1)
  end

  context "versions option" do
    before { stub_const("DummyModel", Class.new(ApplicationRecord)) }

    it "raises a deprecation warning when versions option is not a hash" do
      expect_any_instance_of(ActiveSupport::Deprecation).to receive(:warn)
      DummyModel.has_paper_trail(versions: :my_versions)
    end

    it "accepts versions option as a hash" do
      expect {
        DummyModel.has_paper_trail(versions: { name: :my_versions })
      }.not_to raise_error
    end
  end

  context "model_config" do
    before { stub_const("DummyModel", Class.new(ApplicationRecord)) }
    let(:klass) { DummyModel }

    it "has instance method audit_trail" do
      expect(klass).to respond_to(:audit_trail)
    end

    it "audit_trail has instance method model_class pointing to the klass object" do
      expect(klass.audit_trail).to respond_to(:model_class)
      expect(klass.audit_trail.model_class).to eq(klass)
    end

    it "sets paper_trail_options as a class attribute on the model after has_paper_trail is called" do
      klass.has_paper_trail

      expect(klass).to respond_to(:paper_trail_options)
      expect(klass.paper_trail_options).to be_a(Hash)
    end
  end

  it "stores correct data in the version on update" do
    task = Task.create! valid_attributes
    task.update!(name: "updated name")
    version = AuditVersion.last
    expect(version.item_type).to eq("Task")
    expect(version.item_id).to eq(task.id)
    expect(version.event).to eq("update")
  end
end
