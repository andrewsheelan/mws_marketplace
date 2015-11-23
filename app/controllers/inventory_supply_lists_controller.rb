class InventorySupplyListsController < InheritedResources::Base

  private

    def inventory_supply_list_params
      params.require(:inventory_supply_list).permit(:Condition, :SupplyDetail, :TotalSupplyQuantity, :EarliestAvailability, :FNSKU, :InStockSupplyQuantity, :ASIN, :SellerSKU)
    end
end

