# == Schema Information
#
# Table name: bank_accounts
#
#  account_id   :integer       not null
#  address      :text          
#  agency_code  :string(255)   
#  bank_code    :string(255)   
#  bank_name    :string(50)    
#  bic          :string(16)    
#  company_id   :integer       not null
#  created_at   :datetime      not null
#  creator_id   :integer       
#  currency_id  :integer       not null
#  default      :boolean       not null
#  deleted      :boolean       not null
#  entity_id    :integer       
#  iban         :string(34)    not null
#  iban_label   :string(48)    not null
#  id           :integer       not null, primary key
#  journal_id   :integer       not null
#  key          :string(255)   
#  lock_version :integer       default(0), not null
#  mode         :string(255)   default("IBAN"), not null
#  name         :string(255)   not null
#  number       :string(255)   
#  updated_at   :datetime      not null
#  updater_id   :integer       
#

require 'test_helper'

class BankAccountTest < ActiveSupport::TestCase
  # Replace this with your real tests.
  def test_truth
    assert true
  end
end
