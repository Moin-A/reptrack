require "rails_helper"

RSpec.describe Campaign::PublishesPublication do
  subject(:service) { described_class.new }

  describe "#publish" do
    it "publishes via the platform adapter and records the remote id and url" do
      publication = create(:publication, platform_tag: "test")

      service.publish(publication.id)

      publication.reload
      expect(publication.status).to eq("published")
      expect(publication.remote_id).to eq("test-#{publication.id}")
      expect(publication.url).to be_present
      expect(publication.published_at).to be_present
    end

    it "marks the publication skipped when the platform skips it" do
      publication = create(:publication, platform_tag: "test_skipped")

      service.publish(publication.id)

      expect(publication.reload.status).to eq("skipped")
    end

    it "retries on failure and gives up as failed after the maximum attempts" do
      # drive the retries manually; don't let the re-enqueue run on its own
      allow(Campaign::PublishPublicationJob).to receive(:perform_later)
      publication = create(:publication, platform_tag: "test_failure")

      described_class::MAX_ATTEMPTS.times { service.publish(publication.id) }

      publication.reload
      expect(publication.status).to eq("failed")
      expect(publication.attempts).to eq(described_class::MAX_ATTEMPTS)
      expect(publication.failures.size).to eq(described_class::MAX_ATTEMPTS)
    end

    it "re-enqueues itself while attempts remain" do
      allow(Campaign::PublishPublicationJob).to receive(:perform_later)
      publication = create(:publication, platform_tag: "test_failure")

      service.publish(publication.id) # first of MAX attempts

      expect(publication.reload.status).to eq("wip")
      expect(Campaign::PublishPublicationJob).to have_received(:perform_later).with(publication.id)
    end

    it "does nothing for an already-terminal publication" do
      publication = create(:publication, platform_tag: "test", status: "published")

      expect { service.publish(publication.id) }.not_to(change { publication.reload.status })
    end
  end
end
