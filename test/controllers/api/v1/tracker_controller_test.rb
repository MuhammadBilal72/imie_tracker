require "test_helper"

class Api::V1::TrackerControllerTest < ActionDispatch::IntegrationTest
  test "should get create" do
    get api_v1_tracker_create_url
    assert_response :success
  end
end
