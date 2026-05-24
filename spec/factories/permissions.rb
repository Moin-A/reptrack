FactoryBot.define do
  factory :permission do
    association :user
    association :group
    asset_type { "Lead" }
    asset_id   { 1 }
    action     { "all" }
  end
end
