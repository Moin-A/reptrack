module Campaign
  # Routes Campaign::Foo models to "campaign_foos" tables.
  def self.table_name_prefix
    "campaign_"
  end
end
