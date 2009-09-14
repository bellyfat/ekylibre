# == Schema Information
#
# Table name: bank_account_statements
#
#  bank_account_id :integer       not null
#  company_id      :integer       not null
#  created_at      :datetime      not null
#  creator_id      :integer       
#  credit          :decimal(16, 2 default(0.0), not null
#  debit           :decimal(16, 2 default(0.0), not null
#  id              :integer       not null, primary key
#  intermediate    :boolean       not null
#  lock_version    :integer       default(0), not null
#  number          :string(255)   not null
#  started_on      :date          not null
#  stopped_on      :date          not null
#  updated_at      :datetime      not null
#  updater_id      :integer       
#

require 'test_helper'

class BankAccountStatementTest < ActiveSupport::TestCase
  # Replace this with your real tests.
  def test_truth
    assert true
  end
end
