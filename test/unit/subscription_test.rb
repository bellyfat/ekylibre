# == Schema Information
#
# Table name: subscriptions
#
#  comment       :text          
#  company_id    :integer       not null
#  contact_id    :integer       
#  created_at    :datetime      not null
#  creator_id    :integer       
#  entity_id     :integer       
#  first_number  :integer       
#  id            :integer       not null, primary key
#  invoice_id    :integer       
#  last_number   :integer       
#  lock_version  :integer       default(0), not null
#  nature_id     :integer       
#  product_id    :integer       
#  quantity      :decimal(, )   
#  sale_order_id :integer       
#  started_on    :date          
#  stopped_on    :date          
#  suspended     :boolean       not null
#  updated_at    :datetime      not null
#  updater_id    :integer       
#

require 'test_helper'

class SubscriptionTest < ActiveSupport::TestCase
  # Replace this with your real tests.
  test "the truth" do
    assert true
  end
end
