require 'test_helper'

class Api::CommentLocationsControllerTest < ActionController::TestCase
  
  def setup
    @user = users(:foo)
  end

  test "should return success message on create" do
    log_in_as @user
    response = post :create, comment_id: 1, comment_location: {}
    assert JSON.parse(response.body)['success']
  end


  test "should return success message on update" do
    log_in_as @user
    response = patch :update, comment_id: 1, location_id: 1
    assert JSON.parse(response.body)['success']
  end

  test "should return success message on destroy" do
    log_in_as @user
    response = delete :destroy, comment_id: 1, location_id: 1
    assert JSON.parse(response.body)['success']
  end

end