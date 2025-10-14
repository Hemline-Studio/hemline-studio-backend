class AddFolderColorToFolders < ActiveRecord::Migration[8.0]
  def change
    add_column :folders, :folder_color, :integer, null: false, default: -> { "(floor(random() * 9 + 1))::integer" }

    # Add a check constraint to ensure folder_color is between 1 and 9
    add_check_constraint :folders, "folder_color >= 1 AND folder_color <= 9", name: "folder_color_range"
  end
end
