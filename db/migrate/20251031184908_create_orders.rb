class CreateOrders < ActiveRecord::Migration[8.0]
  def change
    create_table :orders, id: :uuid do |t|
      t.references :client, null: false, foreign_key: true, type: :uuid
      t.references :user, null: false, foreign_key: true, type: :uuid
      t.string :item, null: false
      t.integer :quantity, null: false, default: 1
      t.text :notes
      t.boolean :is_done, default: false, null: false
      t.datetime :due_date

      t.timestamps
    end

    add_index :orders, [ :user_id, :client_id ]
    add_index :orders, :is_done
    add_index :orders, :due_date
  end
end
