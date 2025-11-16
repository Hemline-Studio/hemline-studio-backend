class AddTokenTypeToTokens < ActiveRecord::Migration[8.0]
  def change
    add_column :tokens, :token_type, :string, null: false, default: 'access'
    add_index :tokens, [ :user_id, :token_type ]
  end
end
