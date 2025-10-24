class AddPublicSharingToFolders < ActiveRecord::Migration[8.0]
  def change
    add_column :folders, :is_public, :boolean, default: false, null: false
    add_column :folders, :public_id, :string
    add_index :folders, :public_id, unique: true
  end
end
