# == Schema Information
#
# Table name: listing_nodes
#
#  company_id           :integer       not null
#  comparator           :string(16)    
#  created_at           :datetime      not null
#  creator_id           :integer       
#  exportable           :boolean       default(TRUE), not null
#  id                   :integer       not null, primary key
#  item_listing_id      :integer       
#  item_listing_node_id :integer       
#  item_nature          :string(8)     
#  item_value           :text          
#  label                :string(255)   not null
#  listing_id           :integer       not null
#  lock_version         :integer       default(0), not null
#  name                 :string(255)   not null
#  nature               :string(255)   not null
#  parent_id            :integer       
#  position             :integer       
#  reflection_name      :string(255)   
#  updated_at           :datetime      not null
#  updater_id           :integer       
#

require 'test_helper'

class ListingNodeTest < ActiveSupport::TestCase
  # Replace this with your real tests.
  test "the truth" do
    assert true
  end
end
