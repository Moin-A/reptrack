require "rails_helper"

RSpec.describe Reptrack::Preferences::Preferable do
  # AR requires a named class to instantiate — stub_const gives the anonymous class a name
  let(:klass) do
    stub_const("TestPreferableModel", Class.new(ApplicationRecord) do
      self.table_name = "users"

      include Reptrack::Preferences::Preferable

      alias_method :preferences, :preferences_store

      preference :theme, :string, default: "light"
      preference :locale, :string, default: "en"
    end)
  end

  let(:instance) { klass.new }

  describe ".defined_preferences" do
    it "returns all preferences defined on the class" do
      expect(klass.defined_preferences).to eq([:theme, :locale])
    end

    context "with inheritance" do
      let(:child_class) do
        stub_const("TestPreferableChild", Class.new(klass) do
          preference :notifications, :boolean, default: true
        end)
      end

      it "accumulates parent and child preferences" do
        expect(child_class.defined_preferences).to eq([:theme, :locale, :notifications])
      end

      it "does not pollute the parent's defined_preferences" do
        child_class
        expect(klass.defined_preferences).to eq([:theme, :locale])
      end
    end
  end

  describe "preference getter" do
    it "returns the default value when preference is not set" do
      expect(instance.theme).to eq("light")
    end

    it "returns the set value after assignment" do
      instance.theme = "dark"
      expect(instance.theme).to eq("dark")
    end
  end

  describe "preference setter" do
    it "stores the value in the preferences store" do
      instance.theme = "dark"
      expect(instance.preferences[:theme]).to eq("dark")
    end
  end

  describe "#get_preference" do
    it "returns the value for a defined preference" do
      expect(instance.get_preference(:theme)).to eq("light")
    end

    it "raises NoMethodError for an undefined preference" do
      expect { instance.get_preference(:unknown) }.to raise_error(NoMethodError, /unknown preference not defined/)
    end
  end

  describe "#set_preference" do
    it "sets the value for a defined preference" do
      instance.set_preference(:theme, "dark")
      expect(instance.theme).to eq("dark")
    end

    it "raises NoMethodError for an undefined preference" do
      expect { instance.set_preference(:unknown, "value") }.to raise_error(NoMethodError, /unknown preference not defined/)
    end
  end

  describe "#has_preference?" do
    it "returns true for a defined preference" do
      expect(instance.has_preference?(:theme)).to be true
    end

    it "returns false for an undefined preference" do
      expect(instance.has_preference?(:unknown)).to be false
    end

    it "accepts string keys" do
      expect(instance.has_preference?("theme")).to be true
    end
  end

  describe "#defined_preferences" do
    it "delegates to the class" do
      expect(instance.defined_preferences).to eq(klass.defined_preferences)
    end
  end

  describe "#default_preferences" do
    it "returns a hash of all preferences with their defaults" do
      expect(instance.default_preferences).to eq({ theme: "light", locale: "en" })
    end
  end

  describe "default as Proc" do
    let(:klass_with_proc_default) do
      stub_const("TestPreferableProc", Class.new(ApplicationRecord) do
        self.table_name = "users"

        include Reptrack::Preferences::Preferable
        alias_method :preferences, :preferences_store
        preference :tags, :array, default: -> { [] }
      end)
    end

    it "evaluates the proc on each instance independently" do
      a = klass_with_proc_default.new
      b = klass_with_proc_default.new
      a.tags << "ruby"
      expect(b.tags).to eq([])
    end
  end
end
