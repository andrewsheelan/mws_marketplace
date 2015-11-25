class InventorySupplyListsController < InheritedResources::Base
  def update
    InventorySupplyList.find(params[:id]).update inventory_supply_list_params
    render nothing: true
  end
  private

    def inventory_supply_list_params
      params.require(:inventory_supply_list).permit( :real_cost )
    end
end
