require 'test_helper'

class UsersControllerTest < ActionController::TestCase
  def setup
    @user = users(:foo)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should accept update of name" do
    log_in_as @user
    patch :update, id: @user.id, user: {
      name: "New Name", 
      current_password: "password"
    }
    assert_redirected_to edit_user_path(@user), "Not redirected."
    newUser = User.find(@user.id)
    assert newUser.name == "New Name", "New name not saved."
    assert newUser.email == @user.email, "Email changed."
    assert newUser.password_digest == @user.password_digest, "Password changed."
    assert newUser.activated, "Activation removed."
  end

  test "should accept update of email" do
    log_in_as @user
    patch :update, id: @user.id, user: {
      email: "new@email.com", 
      current_password: "password"
    }
    assert_redirected_to edit_user_path(@user), "Not redirected."
    newUser = User.find(@user.id)
    assert newUser.name == @user.name, "Name changed."
    assert newUser.email == "new@email.com", "Email not changed."
    assert newUser.password_digest == @user.password_digest, "Password changed."
    assert_not newUser.activated, "Activation not removed."
  end


  test "should accept update of password" do
    log_in_as @user
    patch :update, id: @user.id, user: {
      password: "password2",
      password_confirmation: "password2",
      current_password: "password"
    }
    assert_redirected_to edit_user_path(@user), "Not redirected."
    newUser = User.find(@user.id)
    assert newUser.name == @user.name, "Name changed."
    assert newUser.email == @user.email, "Email changed."
    assert newUser.authenticate("password2"), "Password not saved."
    assert newUser.activated, "Activation removed."
  end


  test "a user shouldn't be able to change another users information." do
    log_in_as users(:bar)
    patch :update, id: @user.id, user: {
      name: "New name",
      email: "new@email.com",
      password: "password2",
      password_confirmation: "password2",
      current_password: "password"
    }
    assert_redirected_to :root, "Not redirected."
    newUser = User.find(@user.id)
    assert newUser.name == @user.name, "Name changed."
    assert newUser.email == @user.email, "Email changed."
    assert newUser.password_digest == @user.password_digest, "Password changed."
    assert newUser.activated, "Activation removed."
  end

  test "a user shouldn't be able to change information if not logged in." do
    patch :update, id: @user.id, user: {
      name: "New name",
      email: "new@email.com",
      password: "password2",
      password_confirmation: "password2",
      current_password: "password"
    }
    assert_redirected_to :login, "Not redirected."
    newUser = User.find(@user.id)
    assert newUser.name == @user.name, "Name changed."
    assert newUser.email == @user.email, "Email changed."
    assert newUser.password_digest == @user.password_digest, "Password changed."
    assert newUser.activated, "Activation removed."
  end


  test "user should be able to edit their own settings" do
    log_in_as @user
    get :edit, id: @user.id
    assert_response :success
  end

  test "user shouldn't be able to edit another user" do
    log_in_as @user
    get :edit, id: users(:bar).id
    assert_redirected_to :root
  end

  test "should accept deletion" do
    delete :destroy, id: 1
    assert_redirected_to :root
  end
end