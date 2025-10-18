class AddBusinessImageToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :business_image, :string
    add_column :users, :business_image_public_id, :string
  end
end
