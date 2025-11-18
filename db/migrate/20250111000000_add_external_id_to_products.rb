class AddExternalIdToProducts < ActiveRecord::Migration[8.1]
  def change
    add_column :products, :external_id, :string
    add_index :products, :external_id, unique: true
  end
end

