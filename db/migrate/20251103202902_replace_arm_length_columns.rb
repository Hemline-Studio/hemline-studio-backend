class ReplaceArmLengthColumns < ActiveRecord::Migration[8.0]
  def change
    # Remove the old columns
    remove_column :clients, :arm_length_full, :decimal, precision: 10, scale: 2
    remove_column :clients, :arm_length_three_quarter, :decimal, precision: 10, scale: 2
    
    # Add the new combined column
    add_column :clients, :arm_length_full_three_quarter, :decimal, precision: 10, scale: 2
  end
end
