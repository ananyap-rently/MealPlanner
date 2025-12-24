require "test_helper"

class RoleSelectionsControllerTest < ActionDispatch::IntegrationTest
  test "should get new" do
    get role_selections_new_url
    assert_response :success
  end

  test "should get create" do
    get role_selections_create_url
    assert_response :success
  end
end
