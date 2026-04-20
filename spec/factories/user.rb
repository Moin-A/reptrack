FactoryBot.define { 
    factory :user do
        name {"test_user"}
        email { "testuser@gmail.com"}
        password { 123456 }
    end 
}