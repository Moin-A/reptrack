require "rails_helper"

RSpec.describe Reptrack::Preferences::Persistable do
  let(:klass) do
    Class.new(ApplicationRecord) do
      self.table_name = "users"

      include Reptrack::Preferences::Persistable

      preference :theme, :string, default: "light"
      preference :locale, :string, default: "en"

      # ||= {} guard prevents nil.fetch errors before initialize_preferences_defaults runs
      def preferences
        @preferences ||= {}
      end

      def preferences=(val)
        @preferences = val
      end

      def has_attribute?(attr)
        attr.to_s == "preferences"
      end
    end
  end

  describe "#initialize_preferences_defaults" do
    context "when preferences column is present" do
      it "merges defaults into an empty preferences hash" do
        instance = klass.new
        expect(instance.preferences).to eq({ theme: "light", locale: "en" })
      end

      it "preserves existing values and fills in missing defaults" do
        instance = klass.new
        instance.preferences = { theme: "dark" }
        instance.send(:initialize_preferences_defaults)
        expect(instance.preferences[:theme]).to eq("dark")
        expect(instance.preferences[:locale]).to eq("en")
      end

      it "does not overwrite existing values with defaults" do
        instance = klass.new
        instance.preferences = { theme: "dark", locale: "fr" }
        instance.send(:initialize_preferences_defaults)
        expect(instance.preferences).to eq({ theme: "dark", locale: "fr" })
      end
    end

    context "when preferences column is absent" do
      let(:klass_without_column) do
        Class.new(ApplicationRecord) do
          self.table_name = "users"

          include Reptrack::Preferences::Persistable

          preference :theme, :string, default: "light"

          def has_attribute?(attr)
            false
          end
        end
      end

      it "does not raise an error" do
        expect { klass_without_column.new }.not_to raise_error
      end
    end
  end

  describe "Preferable interface" do
    it "exposes defined_preferences from Preferable" do
      instance = klass.new
      expect(instance.defined_preferences).to eq([:theme, :locale])
    end

    it "can get and set preferences" do
      instance = klass.new
      instance.set_preference(:theme, "dark")
      expect(instance.get_preference(:theme)).to eq("dark")
    end
  end
end
