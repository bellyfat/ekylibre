# == Schema Information
#
# Table name: journal_records
#
#  closed           :boolean       
#  company_id       :integer       not null
#  created_at       :datetime      not null
#  created_on       :date          not null
#  creator_id       :integer       
#  credit           :decimal(16, 2 default(0.0), not null
#  debit            :decimal(16, 2 default(0.0), not null
#  financialyear_id :integer       
#  id               :integer       not null, primary key
#  journal_id       :integer       not null
#  lock_version     :integer       default(0), not null
#  number           :string(255)   not null
#  position         :integer       not null
#  printed_on       :date          not null
#  resource_id      :integer       
#  resource_type    :string(255)   
#  status           :string(1)     default("A"), not null
#  updated_at       :datetime      not null
#  updater_id       :integer       
#

require 'test_helper'

class JournalRecordTest < ActiveSupport::TestCase
  # Replace this with your real tests.
  def test_truth
    assert true
  end
end
