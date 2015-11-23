ActiveAdmin.register InventorySupplyList do
  scope :all
  scope :immediately
# See permitted parameters documentation:
# https://github.com/activeadmin/activeadmin/blob/master/docs/2-resource-customization.md#setting-up-strong-parameters
#
# permit_params :list, :of, :attributes, :on, :model
#
# or
#
# permit_params do
#   permitted = [:permitted, :attributes]
#   permitted << :other if resource.something?
#   permitted
# end

  collection_action :refresh_inventory do
  end

  controller do
    # This code is evaluated within the controller class

    def refresh_inventory
      # Instance method
      client = MWS::FulfillmentInventory::Client.new
      inventory_xml = client.list_inventory_supply(query_start_date_time: (Date.today - 1.day ).iso8601)
      inventory_list = inventory_xml.parse
      inventory_list['InventorySupplyList']['member'].each do |inventory|
        db_inventory = InventorySupplyList.find_or_create_by(fnsku: inventory['FNSKU'])
        avail = inventory['EarliestAvailability'] || {}
        db_inventory.update(
          condition: inventory['Condition'],
          supply_detail: inventory['SupplyDetail'],
          total_supply_quantity: inventory['TotalSupplyQuantity'],
          in_stock_supply_quantity: inventory['InStockSupplyQuantity'],
          asin: inventory['ASIN'],
          seller_sku: inventory['SellerSKU'],
          earliest_availability: (avail['TimepointType']=='DateTime' ? DateTime.parse(avail['DateTime']) : avail['TimepointType'])
        )
      end

      redirect_to collection_path, notice: "inventory refreshed successfully!"
    end
  end

  action_item :refresh_inventory, only: :index do
    link_to 'Refresh Inventory', "#{collection_path}/refresh_inventory"
  end

  def scoped_collection
    super.includes :immediately # prevents N+1 queries to your database
  end
end
