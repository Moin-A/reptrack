require 'rails_helper'

RSpec.describe "Leads convert", type: :request do
  let(:user)     { create(:user, confirmed_at: Time.current) }
  let(:assignee) { create(:user, confirmed_at: Time.current) }

  # access: "Public" lets the lead pass CanCanCan authorization for a non-admin.
  let(:lead) do
    create(:lead,
      user:    user,
      company: "Acme Corp",
      email:   "jane@acme.test",
      phone:   "555-1234",
      title:   "Project Manager",
      status:  "new")
  end

  before { sign_in user }

  # The frontend nests the convert payload under :lead, matching the other
  # lead endpoints. Wrap here so the spec exercises the real request shape.
  def convert!(payload)
    post convert_lead_path(lead), params: { lead: payload }, as: :json
  end

  describe "creating a new account" do
    let(:payload) { { account: { name: "Acme Corp", email: "jane@acme.test" }, opportunity: { name: "Acme — 500 seats", stage: "prospecting", amount: "5000.0", probability: 40 }, assignee_id: assignee.id } }

    it "creates an Account and a Contact, and marks the lead converted" do
      expect { convert!(payload) }
        .to change(Account, :count).by(1)
        .and change(Contact, :count).by(1)

      expect(response).to have_http_status(:ok)
      expect(lead.reload.status).to eq("converted")
    end

    it "copies the lead's fields onto the contact and links both records" do
      convert!(payload)

      contact = Contact.last
      expect(contact.first_name).to eq(lead.first_name)
      expect(contact.last_name).to  eq(lead.last_name)
      expect(contact.email).to      eq("jane@acme.test")
      expect(contact.title).to      eq("Project Manager")
      expect(contact.lead_id).to    eq(lead.id)
      expect(contact.account_id).to eq(Account.last.id)
      expect(contact.assignee_id).to eq(assignee.id)
    end

    it "seeds the new account from the lead" do
      convert!(payload)
      account = Account.last
      expect(account.name).to  eq("Acme Corp")
      expect(account.email).to eq("jane@acme.test")
      expect(account.access).to eq("Private")
    end

    # Without an owner the account is invisible: CanCan only grants access when a
    # record is Public, assigned to you, or owned by you. A nil user_id would let
    # the account be created and then vanish from the accounts list.
    it "gives the new account an owner so it is visible to the user" do
      convert!(payload)
      account = Account.last

      expect(account.user_id).to     eq(lead.user_id)
      expect(account.assignee_id).to eq(assignee.id)
      expect(Account.accessible_by(Ability.new(user))).to include(account)
    end

    it "cascades to contacts and opportunities when the account is deleted" do
      convert!(payload)
      account = Account.last

      expect { account.destroy! }
        .to change(Contact, :count).by(-1)
        .and change(Opportunity, :count).by(-1)
    end

    it "does not create an opportunity when no name is given" do
      payload[:opportunity][:name] = nil
      expect { convert!(payload) }.not_to change(Opportunity, :count)
      expect(response.parsed_body["opportunity"]).to be_nil
    end
  end

  describe "linking to an existing account" do
    let!(:existing) { Account.create!(name: "Acme Corp", email: "ops@acme.test") }

    it "reuses the account instead of creating one" do
      expect { convert!({ account: { id: existing.id }, opportunity: { name: "Acme — 500 seats", stage: "prospecting", amount: "5000.0", probability: 40 }, assignee_id: assignee.id }) }
        .to change(Contact, :count).by(1)
        .and change(Account, :count).by(0)

      expect(response).to have_http_status(:ok)
      expect(Contact.last.account_id).to eq(existing.id)
    end
  end

  describe "with an opportunity" do
    let(:payload) do
      {
        account:     { name: "Acme Corp" },
        assignee_id: assignee.id,
        opportunity: { name: "Acme — 500 seats", stage: "prospecting", amount: "5000.0", probability: 40 }
      }
    end

    it "creates the opportunity attached to the account and lead" do
      expect { convert!(payload) }.to change(Opportunity, :count).by(1)

      opportunity = Opportunity.last
      expect(opportunity.name).to        eq("Acme — 500 seats")
      expect(opportunity.stage).to       eq("prospecting")
      expect(opportunity.amount).to      eq(5000.0)
      expect(opportunity.probability).to eq(40)
      expect(opportunity.account_id).to  eq(Account.last.id)
      expect(opportunity.lead_id).to     eq(lead.id)

      expect(response.parsed_body["opportunity"]["name"]).to eq("Acme — 500 seats")
    end
  end

  describe "when conversion fails" do
    # No account name and no company on the lead => the account cannot be built.
    let(:lead) { create(:lead, user: user, company: nil, email: "jane@acme.test") }

    it "writes nothing and leaves the lead unconverted" do
      expect { convert!({ account: {}, assignee_id: assignee.id }) }
        .to change(Account, :count).by(0)
        .and change(Contact, :count).by(0)

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.parsed_body["errors"]).to be_present
      expect(lead.reload.status).not_to eq("converted")
    end
  end
end
