require 'test_helper'
module Backend
  class OutgoingPaymentsControllerTest < Ekylibre::Testing::ApplicationControllerTestCase::WithFixtures
    # TODO: Re-activate #show, #unroll, #update, #destroy, #edit, #new, #create
    # and #index tests
    test_restfully_all_actions except: %i[show unroll update destroy edit new create index]
  end
end
