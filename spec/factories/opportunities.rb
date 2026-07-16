FactoryBot.define do
  factory :opportunity do
    sequence(:name) { |n| "Opportunity #{n}" }
    stage       { "prospecting" }
    amount      { 5000.0 }
    probability { 40 }
    access      { "Public" }
    association :user
  end
end
