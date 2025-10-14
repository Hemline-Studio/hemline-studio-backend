class ChangeGalleryIdToUuid < ActiveRecord::Migration[8.0]
  def up
    # First, clear all existing galleries data
    execute "TRUNCATE TABLE galleries CASCADE"

    # Drop the old id column
    remove_column :galleries, :id

    # Add new UUID id column
    add_column :galleries, :id, :uuid, default: "gen_random_uuid()", null: false

    # Set it as primary key
    execute "ALTER TABLE galleries ADD PRIMARY KEY (id)"
  end

  def down
    # Remove UUID id
    remove_column :galleries, :id

    # Recreate the old string id
    execute "ALTER TABLE galleries ADD COLUMN id VARCHAR(16) PRIMARY KEY"
  end
end
