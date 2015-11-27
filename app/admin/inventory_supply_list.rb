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

  collection_action :refresh_inventory
  collection_action :refresh_product_info

  index do
    column(:image) { |i| image_tag i.image }
    column(:title)
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

    def refresh_product_info
      lst = InventorySupplyList.where(title: nil).pluck(:asin)

      client = MWS::Products::Client.new
      lst.in_groups_of(10) do |group|
        group.compact!

        products = client.get_matching_product(*group).parse
        products.each do |product|
          db_inventory = InventorySupplyList.find_by(asin: product['ASIN'])
          db_inventory.update(image: product['Product']['AttributeSets']['ItemAttributes']['SmallImage']['URL'],
                              title: product['Product']['AttributeSets']['ItemAttributes']['Title'])
        end
      end

      redirect_to collection_path, notice: "Products refreshed successfully!"

    end

    def refresh_inventory
      # Instance method
      client = MWS::FulfillmentInventory::Client.new
      inventory_xml = client.list_inventory_supply(query_start_date_time: (Date.today - 1.day ).iso8601)
      inventory_list(inventory_xml, client)

      client = MWS::Products::Client.new
      competitive_pricing_for_asin(client)
      get_my_price_for_asin(client)
      lowest_offer_listings_for_asin(client)
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

      lst = InventorySupplyList.where(competitive_pricing: nil).pluck(:asin)
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

    def lowest_offer_listings_for_asin(client)

      lst = InventorySupplyList.where(lowest_offer_listings: nil).pluck(:asin)
      lst.in_groups_of(20) do |group|
        group.compact!

        products = client.get_lowest_offer_listings_for_asin( *group).parse
        products.each do |product|
          db_inventory = InventorySupplyList.find_by(asin: product['ASIN'])

          lowest_offer_listing_prices = product['Product']['LowestOfferListing']['LowestOfferListings']
          if lowest_offer_listing_prices.nil?
            db_inventory.update lowest_offer_listings: 0
          else
            lowest_offer_listing_price = lowest_offer_listing_prices['LowestOfferListingPrice']
            lowest_offer_listing_price = lowest_offer_listing_price.first if lowest_offer_listing_price.is_a? Array
            db_inventory.update lowest_offer_listings: (lowest_offer_listing_price['Price']['LandedPrice']['Amount']).to_f
          end
        end
      end
    end

    def lowest_priced_offers_for_asin(client)

      lst = InventorySupplyList.where(lowest_priced_offers: nil).pluck(:asin)
      lst.each do |group|
        products = client.get_lowest_priced_offers_for_asin( group).parse
        products.each do |product|
          db_inventory = InventorySupplyList.find_by(asin: product['ASIN'])

          lowest_priced_offer_prices = product['Product']['LowestPricedOffer']['LowestPricedOffers']
          if lowest_priced_offer_prices.nil?
            db_inventory.update lowest_priced_offers: 0
          else
            lowest_priced_offer_price = lowest_priced_offer_prices['LowestPricedOffersPrice']
            lowest_priced_offer_price = lowest_priced_offer_price.first if lowest_priced_offer_price.is_a? Array
            db_inventory.update lowest_priced_offers: (lowest_priced_offer_price['Price']['LandedPrice']['Amount']).to_f
          end
        end
      end
    end

    def get_my_price_for_asin(client)
      lst = InventorySupplyList.where(my_price: nil).pluck(:asin)
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

  action_item :refresh_product_info, only: :index do
    link_to 'Refresh Product Information', "#{collection_path}/refresh_product_info"
  end

  def scoped_collection
    super.includes :immediately # prevents N+1 queries to your database
  end
end
