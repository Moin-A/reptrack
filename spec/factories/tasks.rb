FactoryBot.define do
  factory :task do
    name { "MyString" }
    description { "MyString" }
    due_date { "2026-04-23 02:43:23" }
    status { 1 }
  end
end
