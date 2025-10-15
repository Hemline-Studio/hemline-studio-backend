class UpdateGalleryFileNameAndAddDescription < ActiveRecord::Migration[8.0]
  def change
    rename_column :galleries, :filename, :file_name
    add_column :galleries, :description, :text
  end
end
