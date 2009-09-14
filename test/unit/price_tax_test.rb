# == Schema Information
#
# Table name: price_taxes
#
#  amount       :decimal(16, 4 default(0.0), not null
#  company_id   :integer       not null
#  created_at   :datetime      not null
#  creator_id   :integer       
#  id           :integer       not null, primary key
#  lock_version :integer       default(0), not null
#  price_id     :integer       not null
#  tax_id       :integer       not null
#  updated_at   :datetime      not null
#  updater_id   :integer       
#

require 'test_helper'

class PriceTaxTest < ActiveSupport::TestCase
  # Replace this with your real tests.
  def test_truth
    assert true
  end
end
