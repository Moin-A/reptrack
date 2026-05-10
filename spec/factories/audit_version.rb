FactoryBot.define do
  factory :audit_version, class: "Audit::Version" do
    item_type { "Task" }
    sequence(:item_id)
    event { "create" }
    whodunnit { nil }
  end
end
