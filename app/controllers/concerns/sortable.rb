# Maps friendly ?sort= values from the frontend to Ransack sort expressions.
# Included once in ApplicationController so any index action can pass
# `s: sort_expression` to ransack.
module Sortable
  extend ActiveSupport::Concern

  SORT_KEYS = {
    "oldest" => "created_at asc",
    "newest" => "created_at desc",
    "name"   => "name asc",
  }.freeze

  private

  # Unknown/missing keys fall back to `default` (nil = ransack's default order).
  def sort_expression(default = "created_at desc")
    SORT_KEYS.fetch(params[:sort], default)
  end
end
