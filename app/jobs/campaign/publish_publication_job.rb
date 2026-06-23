module Campaign
  class PublishPublicationJob < ApplicationJob
    queue_as :default

    def perform(publication_id)
      PublishesPublication.new.publish(publication_id)
    end
  end
end
