class ApplicationRecord < ActiveRecord::Base
  primary_abstract_class

  # SQLite has no UUID type or generator, so string primary keys are filled in here.
  before_create :assign_uuid_primary_key

  # Matches rows whose JSON array column contains value.
  def self.where_json_array_includes(column, value)
    where("EXISTS (SELECT 1 FROM json_each(#{connection.quote_table_name(table_name)}.#{connection.quote_column_name(column)}) WHERE json_each.value = ?)", value)
  end

  private

  def assign_uuid_primary_key
    pk = self.class.primary_key
    return unless pk && self.class.columns_hash[pk]&.type == :string

    self[pk] ||= SecureRandom.uuid
  end
end
