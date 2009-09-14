# == Schema Information
#
# Table name: observations
#
#  company_id   :integer       not null
#  created_at   :datetime      not null
#  creator_id   :integer       
#  description  :text          not null
#  entity_id    :integer       not null
#  id           :integer       not null, primary key
#  importance   :string(10)    not null
#  lock_version :integer       default(0), not null
#  updated_at   :datetime      not null
#  updater_id   :integer       
#

require 'test_helper'

class ObservationTest < ActiveSupport::TestCase
  # Replace this with your real tests.
  test "the truth" do
    assert true
  end
end
