require 'rails_helper'

RSpec.describe ActivitiesController, type: :controller do
  let(:user) { create(:user, confirmed_at: Time.now) }

  before { sign_in user }

  describe "GET #index" do
    context "without a filter" do
      it "returns a successful response" do
        get :index
        expect(response).to have_http_status(:ok)
      end

      it "returns all activities under a groups key" do
        create_list(:audit_version, 3, whodunnit: user.id.to_s)
        get :index
        json = JSON.parse(response.body)
        expect(json["groups"].length).to eq(3)
      end
    end

    context "with a when filter" do
      before do
        create(:audit_version, whodunnit: user.id.to_s, created_at: Time.current)
        create(:audit_version, whodunnit: user.id.to_s, created_at: 1.day.ago)
        create(:audit_version, whodunnit: user.id.to_s, created_at: 5.days.ago)
        create(:audit_version, whodunnit: user.id.to_s, created_at: 20.days.ago)
      end

      it "returns only activities from today" do
        get :index, params: { activity: { when: "today" } }
        json = JSON.parse(response.body)
        expect(json["groups"].length).to eq(1)
      end

      it "returns activities from the past 2 days" do
        get :index, params: { activity: { when: "past_2_days" } }
        json = JSON.parse(response.body)
        expect(json["groups"].length).to eq(2)
      end

      it "returns activities from the past week" do
        get :index, params: { activity: { when: "past_week" } }
        json = JSON.parse(response.body)
        expect(json["groups"].length).to eq(3)
      end

      it "returns activities from the past 30 days" do
        get :index, params: { activity: { when: "past_30_days" } }
        json = JSON.parse(response.body)
        expect(json["groups"].length).to eq(4)
      end
    end

    context "with a by filter" do
      let(:other_user) { create(:user, email: "other@example.com", confirmed_at: Time.now) }

      before do
        create(:audit_version, whodunnit: user.id.to_s)
        create(:audit_version, whodunnit: other_user.id.to_s)
      end

      it "returns only activities performed by the given user" do
        get :index, params: { activity: { by: user.id } }
        json = JSON.parse(response.body)
        expect(json["groups"].length).to eq(1)
        expect(json["groups"].first["whodunnit"]["id"]).to eq(user.id)
      end

      it "excludes activities from other users" do
        get :index, params: { activity: { by: user.id } }
        json = JSON.parse(response.body)
        whodunnit_ids = json["groups"].map { |g| g["whodunnit"]["id"] }
        expect(whodunnit_ids).not_to include(other_user.id)
      end
    end
  end
end
