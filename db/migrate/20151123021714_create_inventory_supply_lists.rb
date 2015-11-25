class CreateInventorySupplyLists < ActiveRecord::Migration
  def change
    create_table :inventory_supply_lists do |t|
      t.string :asin
      t.integer :total_supply_quantity
      t.string :earliest_availability
      t.integer :in_stock_supply_quantity
      t.float :my_selling_price
      t.float :my_price
      t.float :fee
      t.float :lowest_priced_offers
      t.float :lowest_offer_listings
      t.float :competitive_pricing
      t.float :real_cost
      t.float :profit

      t.timestamps
    end
    add_index :inventory_supply_lists, :asin
  end
end
