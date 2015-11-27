class AddImageTitleToInventorySupplyLists < ActiveRecord::Migration
  def change
    add_column :inventory_supply_lists, :image, :string
    add_column :inventory_supply_lists, :title, :string
  end
end
