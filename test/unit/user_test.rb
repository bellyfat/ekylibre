# == Schema Information
#
# Table name: users
#
#  admin             :boolean       default(TRUE), not null
#  company_id        :integer       not null
#  created_at        :datetime      not null
#  creator_id        :integer       
#  credits           :boolean       default(TRUE), not null
#  deleted           :boolean       not null
#  email             :string(255)   
#  first_name        :string(255)   not null
#  free_price        :boolean       default(TRUE), not null
#  hashed_password   :string(64)    
#  id                :integer       not null, primary key
#  language_id       :integer       not null
#  last_name         :string(255)   not null
#  lock_version      :integer       default(0), not null
#  locked            :boolean       not null
#  name              :string(32)    not null
#  reduction_percent :decimal(, )   default(5.0), not null
#  rights            :text          
#  role_id           :integer       not null
#  salt              :string(64)    
#  updated_at        :datetime      not null
#  updater_id        :integer       
#

require 'test_helper'

class UserTest < ActiveSupport::TestCase
  # Replace this with your real tests.
  def test_truth
    assert true
  end
end
