class CreateWaitlists < ActiveRecord::Migration[8.0]
  def change
    create_table :waitlists, id: :uuid do |t|
      t.string :email

      t.timestamps
    end
    add_index :waitlists, :email, unique: true
  end
end
