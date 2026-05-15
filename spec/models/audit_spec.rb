require 'rails_helper'

RSpec.describe Audit::AuditTrail, type: :model do
  let(:valid_attributes) {
    skip("Add a hash of attributes valid for your model")
  }
  let(:user) { create(:user, confirmed_at: Time.now) }

  before do
    Audit::Request.whodunnit = user.id
  end

  after do
    Audit::Request.whodunnit = nil
  end

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
    before { stub_const("Task", Class.new(ApplicationRecord)) }
    let(:klass) { Task }

    it "has instance method audit_trail" do
      expect(klass).to respond_to(:audit_trail)
    end

    it "audit_trail has instance method model_class pointing to the klass object" do
      expect(klass.audit_trail).to respond_to(:model_class)
      expect(klass.audit_trail.model_class).to eq(klass)
    end

    it "sets audit_trail_options as a class attribute on the model after has_paper_trail is called" do
      klass.has_paper_trail

      expect(klass).to respond_to(:audit_trail_options)
      expect(klass.audit_trail_options).to be_a(Hash)
    end

    context "version_class_name" do
      it "defaults to 'Audit::Version' when no class_name is given" do
        klass.has_paper_trail

        expect(klass.version_class_name).to eq("Audit::Version")
      end

      it "uses the provided class_name from versions options" do
        klass.has_paper_trail(versions: { class_name: "MyCustomVersion" })

        expect(klass.version_class_name).to eq("MyCustomVersion")
      end
    end

    context "versions_association_name" do
      it "defaults to :versions when no name is given" do
        klass.has_paper_trail

        expect(klass.versions_association_name).to eq(:versions)
      end

      it "uses the provided name from versions options" do
        klass.has_paper_trail(versions: { name: :my_versions })

        expect(klass.versions_association_name).to eq(:my_versions)
      end
    end

    context "record trail" do
      it "instance has a audit_trail method after has_paper_trail is called" do
        klass.has_paper_trail
        expect(klass.new).to respond_to(:audit_trail)
      end

      it "audit_trail is an instance of Audit::RecordTrail" do
        klass.has_paper_trail

        expect(klass.new.audit_trail).to be_a(Audit::RecordTrail)
      end
    end
  end

  context "Audit::Events::Create" do
    let(:user) { create(:user, confirmed_at: Time.now) }
    before do
      Audit::Request.whodunnit = user.id
    end

    after do
      Audit::Request.whodunnit = nil
    end
    
    it "creates a version record when a task is created" do
      expect {
        create(:task)
      }.to change(Audit::Version, :count).by(1)
    end

    it "sets whodunnit on the version from Audit::Request" do
      Audit::Request.with(whodunnit: "alice@example.com") do
        create(:task)
      end
      expect(Audit::Version.last.whodunnit).to eq("alice@example.com")
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
