class CreateInventorySupplyLists < ActiveRecord::Migration
  def change
    create_table :inventory_supply_lists do |t|
      t.string :fnsku
      t.string :condition
      t.integer :supply_detail
      t.integer :total_supply_quantity
      t.string :earliest_availability
      t.integer :in_stock_supply_quantity
      t.string :asin
      t.string :seller_sku

      t.timestamps
    end
    add_index :inventory_supply_lists, :fnsku
  end
end
