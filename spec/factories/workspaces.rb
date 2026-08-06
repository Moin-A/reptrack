FactoryBot.define do
  factory :workspace do
    sequence(:name) { |n| "workspace#{n}" }
  end
end
