require 'test_helper'

class Api::ProjectsControllerTest < ActionController::TestCase
  def setup
    @user = users(:foo)
    @project = @user.projects.first
  end

  test "should return success message on create" do
    @response = post :create, project: {}
    assert JSON.parse(@response.body)['success']
  end

  test "should return success message on index" do
    log_in_as @user
    @response = get :index
    assert JSON.parse(@response.body)['projects'].size > 0
  end

  test "should return success message on show" do
    @response = get :show, id: 1
    assert JSON.parse(@response.body)['success']
  end

  test "should return success message on update" do
    @response = patch :update, id: 1
    assert JSON.parse(@response.body)['success']
  end

  test "should return success message on delete" do
    @response = delete :destroy, id: 1
    assert JSON.parse(@response.body)['success']
  end
end
