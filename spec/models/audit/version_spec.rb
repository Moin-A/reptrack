require 'rails_helper'

RSpec.describe Audit::Version, type: :model do
  let(:signed_in_user) { create(:user) }
  let(:assigned_to_user) { create(:user) }
  let(:user2) { create(:user) }
  let(:user3) { create(:user) }
  let(:user4) { create(:user) }

  let(:task_update_version) do
    create(
      :audit_version,
      item_type: "Task",
      event: "update",
      whodunnit: signed_in_user.id.to_s,
      object: {
        "id" => 1,
        "name" => "MyString",
        "description" => "MyString",
        "due_date" => "2026-04-23 02:43:23",
        "status" => 1,
        "bucket" => 0,
        "user_id" => signed_in_user.id,
        "assignee_id" => assigned_to_user.id,
        "asset_id" => nil,
        "asset_type" => nil,
        "created_at" => Time.current,
        "updated_at" => Time.current
      }
    )
  end

  let(:task_assigned_to_me_version) do
    create(
      :audit_version,
      item_type: "Task",
      event: "update",
      whodunnit: user2.id.to_s,
      object: {
        "id" => 2,
        "name" => "MyString",
        "description" => "MyString",
        "due_date" => "2026-04-23 02:43:23",
        "status" => 1,
        "bucket" => 0,
        "user_id" => user2.id,
        "assignee_id" => signed_in_user.id,
        "asset_id" => nil,
        "asset_type" => nil,
        "created_at" => Time.current,
        "updated_at" => Time.current
      }
    )
  end

  let(:task_other_users_version) do
    create(
      :audit_version,
      item_type: "Task",
      event: "update",
      whodunnit: user3.id.to_s,
      object: {
        "id" => 3,
        "name" => "MyString",
        "description" => "MyString",
        "due_date" => "2026-04-23 02:43:23",
        "status" => 1,
        "bucket" => 0,
        "user_id" => user3.id,
        "assignee_id" => user4.id,
        "asset_id" => nil,
        "asset_type" => nil,
        "created_at" => Time.current,
        "updated_at" => Time.current
      }
    )
  end

  it "reify returns an instance of the item_type class" do
    version = described_class.new(
      item_type: "User",
      object: { "id" => 1, "name" => "Test User" }
    )
    result = version.reify
    expect(result).to be_an_instance_of(version.item_type.constantize)
  end

  it "responds to visible_to" do
    version = described_class
    expect(version).to respond_to(:visible_to)
  end

  describe ".visible_to" do
    before do
      task_update_version
      task_assigned_to_me_version
      task_other_users_version
    end

    it "returns records the user owns or is assigned to" do
      result = described_class.visible_to(signed_in_user)
      expect(result).to contain_exactly(task_update_version, task_assigned_to_me_version)
    end

    it "returns only the record user2 is involved in" do
      result = described_class.visible_to(user2)
      expect(result).to contain_exactly(task_assigned_to_me_version)
    end

    it "returns only the record user3 is involved in" do
      result = described_class.visible_to(user3)
      expect(result).to contain_exactly(task_other_users_version)
    end

    it "returns all versions when the user is an admin" do
      allow(user4).to receive(:admin?).and_return(true)
      result = described_class.visible_to(user4)
      expect(result).to contain_exactly(
        task_update_version,
        task_assigned_to_me_version,
        task_other_users_version
      )
    end
  end

  describe ".resolve_date_string" do
    let(:now) { Time.current.change(usec: 0) }

    it "returns an array of two elements" do
      travel_to(now) do
        result = described_class.resolve_date_string("today")
        expect(result).to be_an(Array)
        expect(result.length).to eq(2)
      end
    end

    context "when period is 'today'" do
      it "returns start of today and end of today" do
        travel_to(now) do
          start_dt, end_dt = described_class.resolve_date_string("today")
          expect(start_dt).to eq(now.beginning_of_day)
          expect(end_dt).to eq(now.end_of_day)
        end
      end
    end

    context "when period is 'past_2_days'" do
      it "returns 2 days ago and now" do
        travel_to(now) do
          start_dt, end_dt = described_class.resolve_date_string("past_2_days")
          expect(start_dt).to eq(2.days.ago)
          expect(end_dt).to eq(now)
        end
      end
    end

    context "when period is 'past_week'" do
      it "returns 1 week ago and now" do
        travel_to(now) do
          start_dt, end_dt = described_class.resolve_date_string("past_week")
          expect(start_dt).to eq(1.week.ago)
          expect(end_dt).to eq(now)
        end
      end
    end

    context "when period is 'past_30_days'" do
      it "returns 30 days ago and now" do
        travel_to(now) do
          start_dt, end_dt = described_class.resolve_date_string("past_30_days")
          expect(start_dt).to eq(30.days.ago)
          expect(end_dt).to eq(now)
        end
      end
    end
  end
end
