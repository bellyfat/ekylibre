# == Schema Information
#
# Table name: sale_order_lines
#
#  account_id          :integer       not null
#  amount              :decimal(16, 2 default(0.0), not null
#  amount_with_taxes   :decimal(16, 2 default(0.0), not null
#  annotation          :text          
#  company_id          :integer       not null
#  created_at          :datetime      not null
#  creator_id          :integer       
#  entity_id           :integer       
#  id                  :integer       not null, primary key
#  invoiced            :boolean       not null
#  label               :text          
#  location_id         :integer       
#  lock_version        :integer       default(0), not null
#  order_id            :integer       not null
#  position            :integer       
#  price_amount        :decimal(16, 2 
#  price_id            :integer       not null
#  product_id          :integer       not null
#  quantity            :decimal(16, 2 default(1.0), not null
#  reduction_origin_id :integer       
#  tax_id              :integer       
#  unit_id             :integer       not null
#  updated_at          :datetime      not null
#  updater_id          :integer       
#

require 'test_helper'

class SaleOrderLineTest < ActiveSupport::TestCase
  # Replace this with your real tests.
  def test_truth
    assert true
  end
end
