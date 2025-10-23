class AddMetadataToGalleries < ActiveRecord::Migration[8.0]
  def change
    add_column :galleries, :width, :integer
    add_column :galleries, :height, :integer
    add_column :galleries, :aperture, :string
    add_column :galleries, :camera_model, :string
    add_column :galleries, :shutter_speed, :string
    add_column :galleries, :iso, :integer
  end
end
