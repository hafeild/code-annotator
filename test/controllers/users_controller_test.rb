require 'test_helper'

class UsersControllerTest < ActionController::TestCase
  def setup
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should accept create" do
    post :create, user: {}
    assert_redirected_to :root
  end

  test "should accept update" do
    patch :update, id: 1
    assert_redirected_to :root
  end

  test "should get edit" do
    delete :edit, id: 1
    assert_response :success
  end

  test "should accept deletion" do
    delete :destroy, id: 1
    assert_redirected_to :root
  end
end