FactoryBot.define do
  factory :publication, class: "Campaign::Publication" do
    post
    social_account
    status { "ready" }
  end
end
