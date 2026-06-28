require "rails_helper"

RSpec.describe Campaign::CreatesPublication do
  let(:user) { create(:user) }
  subject(:service) { described_class.new(user) }

  before { allow(Campaign::PublishPublicationJob).to receive(:perform_later) }

  it "creates a ready publication per account and enqueues each" do
    post = create(:post, user: user)
    accounts = create_list(:social_account, 2, user: user)

    publications = service.call(post: post, social_account_ids: accounts.map(&:id))

    expect(publications.size).to eq(2)
    expect(publications.map(&:status).uniq).to eq([ "ready" ])
    expect(Campaign::Publication.where(post: post).count).to eq(2)
    expect(Campaign::PublishPublicationJob).to have_received(:perform_later).twice
  end

  it "ignores accounts that don't belong to the user" do
    post = create(:post, user: user)
    other_account = create(:social_account) # different user

    expect(service.call(post: post, social_account_ids: [ other_account.id ])).to be_empty
  end

  it "ignores inactive accounts" do
    post = create(:post, user: user)
    inactive = create(:social_account, user: user, active: false)

    expect(service.call(post: post, social_account_ids: [ inactive.id ])).to be_empty
  end

  it "does not duplicate an existing publication" do
    post = create(:post, user: user)
    account = create(:social_account, user: user)
    create(:publication, post: post, social_account: account)

    expect {
      service.call(post: post, social_account_ids: [ account.id ])
    }.not_to change(Campaign::Publication, :count)
  end
end
