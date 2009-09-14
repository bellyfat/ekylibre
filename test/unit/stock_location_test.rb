# == Schema Information
#
# Table name: stock_locations
#
#  account_id       :integer       not null
#  comment          :text          
#  company_id       :integer       not null
#  contact_id       :integer       
#  created_at       :datetime      not null
#  creator_id       :integer       
#  establishment_id :integer       
#  id               :integer       not null, primary key
#  lock_version     :integer       default(0), not null
#  name             :string(255)   not null
#  number           :integer       
#  parent_id        :integer       
#  product_id       :integer       
#  quantity_max     :float         
#  reservoir        :boolean       
#  unit_id          :integer       
#  updated_at       :datetime      not null
#  updater_id       :integer       
#  x                :string(255)   
#  y                :string(255)   
#  z                :string(255)   
#

require 'test_helper'

class StockLocationTest < ActiveSupport::TestCase
  # Replace this with your real tests.
  def test_truth
    assert true
  end
end
