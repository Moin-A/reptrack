# Bare-minimum Ransack allowlist.
#
# The `.ransack` class method is provided globally by the ransack gem itself;
# this concern only supplies the allowlists Ransack 4+ requires so that
# searching actually returns results instead of silently matching nothing.
module Ransackable
  extend ActiveSupport::Concern

  class_methods do
    def ransackable_attributes(_auth_object = nil)
      column_names
    end

    def ransackable_associations(_auth_object = nil)
      reflect_on_all_associations.map { |a| a.name.to_s }
    end
  end
end
