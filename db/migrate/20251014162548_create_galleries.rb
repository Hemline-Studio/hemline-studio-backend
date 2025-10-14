class CreateGalleries < ActiveRecord::Migration[8.0]
  def change
    create_table :galleries, id: false do |t|
      t.string :id, limit: 16, primary_key: true, null: false
      t.string :filename, null: false
      t.string :url, null: false
      t.string :public_id, null: false
      t.text :folder_ids, array: true, default: []
      t.uuid :user_id, null: false

      t.timestamps
    end

    add_index :galleries, :user_id
    add_index :galleries, :public_id
    add_index :galleries, [ :user_id, :public_id ], unique: true
    add_index :galleries, :folder_ids, using: 'gin'

    add_foreign_key :galleries, :users
  end
end
