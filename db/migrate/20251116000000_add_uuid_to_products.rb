class AddUuidToProducts < ActiveRecord::Migration[8.1]
  def change
    add_column :products, :uuid, :string
    add_index :products, :uuid, unique: true
  end
end



