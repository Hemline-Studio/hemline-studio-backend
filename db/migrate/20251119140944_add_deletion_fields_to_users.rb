class AddDeletionFieldsToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :to_be_deleted, :boolean, default: false
    add_column :users, :date_requested_for_deletion, :datetime
  end
end
