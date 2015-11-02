require 'test_helper'

class Api::ProjectsControllerTest < ActionController::TestCase
  def setup
  end

  test "should return success message on create" do
    @response = post :create, project: {}
    assert JSON.parse(@response.body)['success']
  end

  test "should return success message on index" do
    @response = get :index
    assert JSON.parse(@response.body)['success']
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
