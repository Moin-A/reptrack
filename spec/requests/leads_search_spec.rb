require "rails_helper"

RSpec.describe "Leads search", type: :request do
  let(:user) { create(:user, confirmed_at: Time.current) }

  before { sign_in user }

  describe "GET /leads with search/sort params" do
    let!(:jane)  { create(:lead, first_name: "Jane", last_name: "Smith", company: "Acme Corp",   email: "jane@acme.test") }
    let!(:marco) { create(:lead, first_name: "Marco", last_name: "Rossi", company: "Iron Union", email: "marco@iron.test") }

    def returned_first_names
      JSON.parse(response.body)["leads"].map { |l| l["first_name"] }
    end

    it "filters by name" do
      get "/leads", params: { search: "jane" }

      expect(response).to have_http_status(:ok)
      expect(returned_first_names).to eq([ "Jane" ])
    end

    it "filters by company" do
      get "/leads", params: { search: "iron union" }

      expect(returned_first_names).to eq([ "Marco" ])
    end

    it "returns everything for a blank search" do
      get "/leads", params: { search: "" }

      expect(returned_first_names).to contain_exactly("Jane", "Marco")
    end

    it "sorts by first/last name for the name sort key" do
      get "/leads", params: { sort: "name" }

      expect(returned_first_names).to eq([ "Jane", "Marco" ])
    end

    it "sorts newest first by default" do
      get "/leads"

      expect(returned_first_names).to eq([ "Marco", "Jane" ])
    end
  end
end
