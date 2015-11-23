require 'test_helper'

class InventorySupplyListsControllerTest < ActionController::TestCase
  setup do
    @inventory_supply_list = inventory_supply_lists(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:inventory_supply_lists)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create inventory_supply_list" do
    assert_difference('InventorySupplyList.count') do
      post :create, inventory_supply_list: { ASIN: @inventory_supply_list.ASIN, Condition: @inventory_supply_list.Condition, EarliestAvailability: @inventory_supply_list.EarliestAvailability, FNSKU: @inventory_supply_list.FNSKU, InStockSupplyQuantity: @inventory_supply_list.InStockSupplyQuantity, SellerSKU: @inventory_supply_list.SellerSKU, SupplyDetail: @inventory_supply_list.SupplyDetail, TotalSupplyQuantity: @inventory_supply_list.TotalSupplyQuantity }
    end

    assert_redirected_to inventory_supply_list_path(assigns(:inventory_supply_list))
  end

  test "should show inventory_supply_list" do
    get :show, id: @inventory_supply_list
    assert_response :success
  end

  test "should get edit" do
    get :edit, id: @inventory_supply_list
    assert_response :success
  end

  test "should update inventory_supply_list" do
    patch :update, id: @inventory_supply_list, inventory_supply_list: { ASIN: @inventory_supply_list.ASIN, Condition: @inventory_supply_list.Condition, EarliestAvailability: @inventory_supply_list.EarliestAvailability, FNSKU: @inventory_supply_list.FNSKU, InStockSupplyQuantity: @inventory_supply_list.InStockSupplyQuantity, SellerSKU: @inventory_supply_list.SellerSKU, SupplyDetail: @inventory_supply_list.SupplyDetail, TotalSupplyQuantity: @inventory_supply_list.TotalSupplyQuantity }
    assert_redirected_to inventory_supply_list_path(assigns(:inventory_supply_list))
  end

  test "should destroy inventory_supply_list" do
    assert_difference('InventorySupplyList.count', -1) do
      delete :destroy, id: @inventory_supply_list
    end

    assert_redirected_to inventory_supply_lists_path
  end
end
