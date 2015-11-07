require 'test_helper'

class Api::AltcodeControllerTest < ActionController::TestCase

  def setup
    @user = users(:foo)
  end

  test "should return success message on create" do
    log_in_as @user
    @response = post :create, project_id: 1, altcode: {}
    assert JSON.parse(@response.body)['success']
  end

  test "should return success message on index by project" do
    log_in_as @user
    @response = get :index, project_id: 1
    assert JSON.parse(@response.body)['success']
  end

  test "should return success message on index by file" do
    log_in_as @user
    @response = get :index, project_id: 1, file_id: 1
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
