FactoryBot.define do
  factory :post, class: "Campaign::Post" do
    association :user
    content { "Hello from the campaign feature" }
  end
end
