require 'rails_helper'

RSpec.describe Audit::Version, type: :model do
  it "reify returns an instance of the item_type class" do
    version = described_class.new(
      item_type: "User",
      object: { "id" => 1, "name" => "Test User" }
    )
    result = version.reify
    expect(result).to be_an_instance_of(version.item_type.constantize)
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
