json.array!(@inventory_supply_lists) do |inventory_supply_list|
  json.extract! inventory_supply_list, :id, :Condition, :SupplyDetail, :TotalSupplyQuantity, :EarliestAvailability, :FNSKU, :InStockSupplyQuantity, :ASIN, :SellerSKU
  json.url inventory_supply_list_url(inventory_supply_list, format: :json)
end
