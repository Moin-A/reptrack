FactoryBot.define do
  factory :publication, class: "Campaign::Publication" do
    transient do
      platform_tag { "test" }
    end

    post
    social_account { association(:social_account, platform_tag: platform_tag) }
    status { "ready" }
  end
end
