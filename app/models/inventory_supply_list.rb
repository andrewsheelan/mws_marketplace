class InventorySupplyList < ActiveRecord::Base
  scope :immediately, -> { where(earliest_availability: 'Immediately') }
end
