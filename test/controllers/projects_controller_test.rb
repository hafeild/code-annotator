require 'test_helper'

class ProjectsControllerTest < ActionController::TestCase
  def setup
  end

  test "should get index" do
    get :index
    assert_response :success
  end

  test "should get show" do
    get :show, id: 1
    assert_response :success
  end
  
end
