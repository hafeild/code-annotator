require 'test_helper'

class ProjectsControllerTest < ActionController::TestCase
  def setup
    @user = users(:foo)
    @project = @user.projects.first
  end

  test "should get index when logged in" do
    log_in_as(@user)
    get :index
    assert_response :success
  end

  test "should get show when logged in" do
    log_in_as(@user)
    get :show, id: @project
    assert_response :success
  end

  test "should not be shown unauthorized projects" do
    log_in_as(@user)
    get :show, id: projects(:p2)
    assert_redirected_to projects_url
  end

  test "index should redirect to login when logged out" do
    get :index
    assert_redirected_to login_url
  end

  test "show should redirect to login when logged out" do
    get :show, id: @project
    assert_redirected_to login_url
  end
end
