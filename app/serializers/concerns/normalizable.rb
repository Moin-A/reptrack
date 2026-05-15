module Normalizable
  extend ActiveSupport::Concern

  class_methods do
    def normalize(record)
      new(record).serializable_hash[:data][:attributes]
    end
  end
end
