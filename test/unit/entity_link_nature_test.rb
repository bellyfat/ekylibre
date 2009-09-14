# == Schema Information
#
# Table name: entity_link_natures
#
#  comment            :text          
#  company_id         :integer       not null
#  created_at         :datetime      not null
#  creator_id         :integer       
#  id                 :integer       not null, primary key
#  lock_version       :integer       default(0), not null
#  name               :string(255)   not null
#  name_1_to_2        :string(255)   
#  name_2_to_1        :string(255)   
#  propagate_contacts :boolean       not null
#  symmetric          :boolean       not null
#  updated_at         :datetime      not null
#  updater_id         :integer       
#

require 'test_helper'

class EntityLinkNatureTest < ActiveSupport::TestCase
  # Replace this with your real tests.
  test "the truth" do
    assert true
  end
end
