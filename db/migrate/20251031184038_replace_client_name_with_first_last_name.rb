class ReplaceClientNameWithFirstLastName < ActiveRecord::Migration[8.0]
  def up
    # Add new columns
    add_column :clients, :first_name, :string
    add_column :clients, :last_name, :string

    # Remove old name column
    remove_column :clients, :name, :string
  end

  def down
    # Add back the name column
    add_column :clients, :name, :string


    # Remove the split columns
    remove_column :clients, :first_name, :string
    remove_column :clients, :last_name, :string
  end
end
