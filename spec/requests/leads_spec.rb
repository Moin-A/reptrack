require 'rails_helper'

RSpec.describe "Leads", type: :request do
  let(:referer) { create(:user, confirmed_at: Time.current) }
  let(:assignee) { create(:user, confirmed_at: Time.current) }
  let(:user) { create(:user, confirmed_at: Time.current) }

  # access: "Public" lets the lead pass CanCanCan authorization
  # (load_and_authorize_resource) for a non-admin user.
  let(:valid_attributes) {
  {
      first_name:   "Jane",
      last_name:    "Smith",
      status:       "New",
      source:      "Web",
      tags:        [ "tag1", "tag2" ],
      assignee_id:  assignee.id,
      rating:      5,
      campaign:    "Spring Sale",
      referred_by: referer.id,
      do_not_call: false,
      permissions: "Read",
      title:       "Marketing Manager",
      company:    "Acme Corp",
      email:     "jane.smith@example.com",
      phone:     "555-1234",
      alt_email: "jane.smith@work.com",
      mobile:    "555-5678",
      website:   "www.janesmith.com",
      linkedin:  "linkedin.com/in/janesmith",
      facebook:  "facebook.com/janesmith",
      twitter:   "twitter.com/janesmith",
      business_address_attributes: {
        street1:    "123 Main St",
        street2:    "Apt 4B",
        city:       "Anytown",
        state:      "CA",
        zipcode:        "12345",
        country:    "USA"
      }
   }
 }


  let(:invalid_attributes) {
    valid_attributes.merge(first_name: "Jane123")
  }

  before { sign_in user }

  describe "POST /create" do
    context "with valid parameters" do
      it "creates a new Lead" do
        expect {
          post leads_url, params: { lead: valid_attributes }, as: :json
        }.to change(Lead, :count).by(1).and change(Address, :count).by(1)
      end

      it "renders a JSON response with the new lead" do
        post leads_url, params: { lead: valid_attributes }, as: :json

        expect(response).to have_http_status(:created)
        expect(response.content_type).to match(a_string_including("application/json"))
        expect(response.parsed_body["lead"]).to be_present
        expect(response.parsed_body["lead"]["id"]).to be_present
        expect(response.parsed_body["lead"]["business_address"]).to be_present
        expect(response.parsed_body["lead"]["business_address"]["id"]).to be_present
      end

      it "persists the submitted attributes" do
        post leads_url, params: { lead: valid_attributes }, as: :json

        lead = Lead.last
        expect(lead.first_name).to eq("Jane")
        expect(lead.last_name).to eq("Smith")
        expect(lead.email).to eq("jane.smith@example.com")
      end
    end

    context "with invalid parameters" do
      it "does not create a new Lead" do
        expect {
          post leads_url, params: { lead: invalid_attributes }, as: :json
        }.not_to change(Lead, :count)
      end

      it "renders a JSON response with errors for the new lead" do
        post leads_url, params: { lead: invalid_attributes }, as: :json

        expect(response).to have_http_status(:unprocessable_content)
        expect(response.content_type).to match(a_string_including("application/json"))
        expect(response.parsed_body["errors"]).to be_present
      end
    end

    context "convert" do
      let(:lead) { create(:lead, **valid_attributes.except(:campaign, :tags, :permissions, :website)) }

      # The convert payload nests under :lead, like the other lead endpoints.
      let(:convert_params) do
        {
          lead: {
            # Account validates email format and does not allow it blank.
            opportunity: { name: "Acme — 500 seats", stage: "prospecting", amount: "5000.0", probability: 40 },
            account:     { name: "Acme Corp", email: "ops@acme.test" },
            assignee_id: assignee.id
          }
        }
      end

      it "creates a contact and lead linked to the lead" do
        expect {
          post convert_lead_url(lead), params: convert_params, as: :json
        }.to change(Contact, :count).by(1)

        expect(response).to have_http_status(:ok)
        expect(Contact.last.lead_id).to eq(lead.id)
        expect(lead.reload.status).to eq("converted")
      end
    end
  end
end
