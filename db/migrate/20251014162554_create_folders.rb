class CreateFolders < ActiveRecord::Migration[8.0]
  def change
    create_table :folders, id: :uuid do |t|
      t.string :name, null: false
      t.text :description
      t.text :image_ids, array: true, default: []
      t.string :cover_image
      t.uuid :user_id, null: false

      t.timestamps
    end

    add_index :folders, :user_id
    add_index :folders, [ :user_id, :name ], unique: true
    add_index :folders, :image_ids, using: 'gin'

    add_foreign_key :folders, :users
  end
end
