Rails.application.config.generators do |g|
  # UUID strings, filled in by ApplicationRecord (SQLite has no uuid type)
  g.orm :active_record, primary_key_type: :string
end
