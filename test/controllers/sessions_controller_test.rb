require 'test_helper'

class SessionsControllerTest < ActionController::TestCase
  def setup
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should accept logout" do
    delete :destroy, id: 1
    assert_redirected_to :root
  end
end
