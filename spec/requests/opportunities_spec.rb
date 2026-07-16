require 'rails_helper'

RSpec.describe "Opportunities", type: :request do
  let(:user)     { create(:user, confirmed_at: Time.current) }
  let(:assignee) { create(:user, confirmed_at: Time.current) }
  let(:account)  { Account.create!(name: "Acme Corp", email: "ops@acme.test", user: user) }

  before { sign_in user }

  describe "GET /opportunities" do
    let!(:mine)   { create(:opportunity, name: "Acme renewal", user: user, account: account, stage: "proposal") }
    let!(:hidden) { create(:opportunity, name: "Someone else's", user: create(:user), access: "Private") }

    it "returns only the opportunities the user can see" do
      get opportunities_path, as: :json

      expect(response).to have_http_status(:ok)
      names = response.parsed_body["opportunities"].map { |o| o["name"] }
      expect(names).to     include("Acme renewal")
      expect(names).not_to include("Someone else's")
    end

    it "serializes the account and owner by name, and amounts as numbers" do
      get opportunities_path, as: :json

      opp = response.parsed_body["opportunities"].find { |o| o["name"] == "Acme renewal" }
      expect(opp["account"]).to     eq("Acme Corp")
      expect(opp["user"]).to        eq(user.name)
      expect(opp["amount"]).to      eq(5000.0)
      expect(opp["probability"]).to eq(40)
      expect(opp["created_at"]).to  be_present
    end

    it "filters by search term" do
      get opportunities_path(search: "renewal"), as: :json

      names = response.parsed_body["opportunities"].map { |o| o["name"] }
      expect(names).to eq([ "Acme renewal" ])
    end
  end

  describe "POST /opportunities" do
    let(:valid_params) do
      { opportunity: {
          name: "New deal", stage: "prospecting", amount: "12000.5",
          probability: 25, account_id: account.id, assignee_id: assignee.id
      } }
    end

    it "creates an opportunity owned by the current user" do
      expect { post opportunities_path, params: valid_params, as: :json }
        .to change(Opportunity, :count).by(1)

      expect(response).to have_http_status(:created)
      opp = Opportunity.last
      expect(opp.name).to        eq("New deal")
      expect(opp.amount).to      eq(12000.5)
      expect(opp.account_id).to  eq(account.id)
      expect(opp.assignee_id).to eq(assignee.id)
      expect(opp.user_id).to     eq(user.id)   # owner, so it stays visible
    end

    it "rejects an opportunity with no name" do
      expect { post opportunities_path, params: { opportunity: { stage: "won" } }, as: :json }
        .not_to change(Opportunity, :count)

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.parsed_body["errors"]).to be_present
    end
  end

  describe "PATCH /opportunities/:id" do
    let!(:opportunity) { create(:opportunity, user: user, stage: "proposal") }

    it "updates the opportunity" do
      patch opportunity_path(opportunity),
            params: { opportunity: { stage: "won", probability: 100 } }, as: :json

      expect(response).to have_http_status(:ok)
      expect(opportunity.reload.stage).to       eq("won")
      expect(opportunity.reload.probability).to eq(100)
    end
  end

  describe "DELETE /opportunities/:id" do
    let!(:opportunity) { create(:opportunity, user: user) }

    it "destroys the opportunity" do
      expect { delete opportunity_path(opportunity), as: :json }
        .to change(Opportunity, :count).by(-1)

      expect(response).to have_http_status(:no_content)
    end
  end
end
