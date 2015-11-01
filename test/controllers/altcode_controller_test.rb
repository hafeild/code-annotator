require 'test_helper'

class AltcodeControllerTest < ActionController::TestCase
  def setup
  end

  test "should return success message on create" do
    @response = post :create, project_id: 1, altcode: {}
    assert JSON.parse(@response.body)['success']
  end

  test "should return success message on index by project" do
    @response = get :index, project_id: 1
    assert JSON.parse(@response.body)['success']
  end

  test "should return success message on index by file" do
    @response = get :index, project_id: 1, file_id: 1
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
