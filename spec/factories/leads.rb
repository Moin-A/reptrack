FactoryBot.define do
  factory :lead do
    first_name { "John" }
    last_name  { "Doe" }
    email      { "john.doe@example.com" }
    access     { "Public" }
    rating     { 0 }
    do_not_call { false }
    association :user
  end
end
