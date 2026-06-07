FactoryBot.define do
  factory :audit_version, class: "Audit::Version" do
    item_type { "Task" }
    sequence(:item_id)
    event { "create" }
    whodunnit { nil }
    object { { "id" => item_id, "name" => "Sample Task", "user_id" => nil, "assignee_id" => nil } }
  end
end
