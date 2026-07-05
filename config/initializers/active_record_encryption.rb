# Active Record Encryption — encrypts sensitive columns at rest
# (e.g. Campaign::SocialAccount#credentials, which holds platform access tokens).
# Keys live in ENV (.env locally, host env vars in production).
Rails.application.configure do
  config.active_record.encryption.primary_key         ||= ENV["AR_ENCRYPTION_PRIMARY_KEY"]
  config.active_record.encryption.deterministic_key   ||= ENV["AR_ENCRYPTION_DETERMINISTIC_KEY"]
  config.active_record.encryption.key_derivation_salt ||= ENV["AR_ENCRYPTION_KEY_DERIVATION_SALT"]

  # Rows written before encryption was enabled are plaintext; keep them readable
  # (they get encrypted on their next save).
  config.active_record.encryption.support_unencrypted_data = true
end
