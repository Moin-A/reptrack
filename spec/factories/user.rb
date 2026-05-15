FactoryBot.define {
    factory :user do
        sequence(:name) { |n| "test_user_#{n}" }
        sequence(:email) { |n| "testuser#{n}@gmail.com" }
        password { 123456 }
    end
}
