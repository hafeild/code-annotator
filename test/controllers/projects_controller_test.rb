require 'test_helper'

class ProjectsControllerTest < ActionController::TestCase
  def setup
    @user = users(:foo)
    @project = @user.projects.first
  end

  test "should get index" do
    log_in_as(@user)
    get :index
    assert_response :success
  end

  test "should get show" do
    log_in_as(@user)
    get :show, id: @project
    assert_response :success
  end
  
end
