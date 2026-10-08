# frozen_string_literal: true

# Collapses Rails' multi-line "Started ... / Processing by ... / Completed
# ... in Xms (...)" request logs into a single JSON line, with controller,
# action, status, and duration already included by lograge by default.
# user_id and request_id are added below so a slow or erroring request can be
# traced back to who made it, and correlated with any other log lines
# tagged with the same request id.
#
# Datadog (and similar log tools) parse well-formed JSON log lines into
# attributes automatically — no Grok parser needed once this is live.
Rails.application.configure do
  config.lograge.enabled = true
  config.lograge.formatter = Lograge::Formatters::Json.new

  # user_id/request_id are added to the payload in ApplicationController
  # (via append_info_to_payload, which runs with controller context); this
  # just pulls them through into the final JSON line.
  config.lograge.custom_options = lambda do |event|
    event.payload.slice(:user_id, :request_id)
  end
end
