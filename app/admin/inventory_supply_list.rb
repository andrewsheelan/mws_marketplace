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

  index do
    column(:asin)
    column(:total_supply_quantity)
    column(:earliest_availability)
    column(:in_stock_supply_quantity)
    column(:my_selling_price)
    column(:my_price)
    column(:fee)
    column(:lowest_priced_offers)
    column(:lowest_offer_listings)
    column(:competitive_pricing)
    column(:real_cost) { |i| best_in_place i, :real_cost, :type => :input, :path => [:admin, i] }
    column(:profit)
  end

  controller do
    # This code is evaluated within the controller class

    def refresh_inventory
      # Instance method
      client = MWS::FulfillmentInventory::Client.new
      inventory_xml = client.list_inventory_supply(query_start_date_time: (Date.today - 1.day ).iso8601)
      inventory_list(inventory_xml, client)

      client = MWS::Products::Client.new
      competitive_pricing_for_asin(client)
      get_my_price_for_asin(client)
      redirect_to collection_path, notice: "inventory refreshed successfully!"
    end

    def inventory_list(inventory_xml, client)
      inventory_list = inventory_xml.parse
      inventory_list['InventorySupplyList']['member'].each do |inventory|
        db_inventory = InventorySupplyList.find_or_create_by(asin: inventory['ASIN'])
        avail = inventory['EarliestAvailability'] || {}
        db_inventory.update(
          total_supply_quantity: inventory['TotalSupplyQuantity'],
          in_stock_supply_quantity: inventory['InStockSupplyQuantity'],
          earliest_availability: avail['TimepointType']=='DateTime' ? DateTime.parse(avail['DateTime']).to_time.strftime('%B %e, %Y at %l:%M %p') : avail['TimepointType']
        )
      end

      if inventory_list['NextToken'].present?
        inventory_xml = client.list_inventory_supply_by_next_token(inventory_list['NextToken'])
        inventory_list(inventory_xml, client)
      end
    end

    def competitive_pricing_for_asin(client)

      lst = InventorySupplyList.pluck(:asin)
      lst.in_groups_of(20) do |group|
        group.compact!

        products = client.get_competitive_pricing_for_asin( *group).parse
        products.each do |product|
          db_inventory = InventorySupplyList.find_by(asin: product['ASIN'])

          competitive_prices = product['Product']['CompetitivePricing']['CompetitivePrices']
          if competitive_prices.nil?
            db_inventory.update competitive_pricing: 0
          else
            competitive_price = competitive_prices['CompetitivePrice']
            competitive_price = competitive_price.first if competitive_price.is_a? Array
            db_inventory.update competitive_pricing: (competitive_price['Price']['LandedPrice']['Amount']).to_f
          end
        end
      end
    end

    def get_my_price_for_asin(client)
      lst = InventorySupplyList.pluck(:asin)
      lst.in_groups_of(20) do |group|
        group.compact!

        products = client.get_my_price_for_asin( *group).parse
        products.each do |product|
          db_inventory = InventorySupplyList.find_by(asin: product['ASIN'])
          offers = product['Product']['Offers']
          if offers.nil?
            db_inventory.update my_price: 0
          else
            offer = offers['Offer']
            offer = offers.first if offer.is_a? Array
            db_inventory.update my_price: (offer['BuyingPrice']['LandedPrice']['Amount']).to_f
          end
        end
      end
    end
  end

  action_item :refresh_inventory, only: :index do
    link_to 'Refresh Inventory', "#{collection_path}/refresh_inventory"
  end

  def scoped_collection
    super.includes :immediately # prevents N+1 queries to your database
  end
end
