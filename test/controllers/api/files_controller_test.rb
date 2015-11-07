require 'test_helper'

class Api::FilesControllerTest < ActionController::TestCase
  
  def setup
    @user = users(:foo)
  end

  test "should return success message on create" do
    log_in_as @user
    @response = post :create, project_id: 1, file: {}
    assert JSON.parse(@response.body)['success']
  end

  test "should return success message on index" do
    log_in_as @user
    @response = get :index, project_id: 1
    assert JSON.parse(@response.body)['success']
  end

  test "should return success message on download" do
    log_in_as @user
    @response = get :download, project_id: 1
    assert JSON.parse(@response.body)['success']
  end

  test "should return success message on print" do
    log_in_as @user
    @response = get :print, project_id: 1
    assert JSON.parse(@response.body)['success']
  end

  test "should return success message on show" do
    log_in_as @user
    @response = get :show, id: 1
    assert JSON.parse(@response.body)['success']
  end

  test "should return success message on update" do
    log_in_as @user
    @response = patch :update, id: 1
    assert JSON.parse(@response.body)['success']
  end

  test "should return success message on delete" do
    log_in_as @user
    @response = delete :destroy, id: 1
    assert JSON.parse(@response.body)['success']
  end
end
