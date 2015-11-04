require 'test_helper'

class UsersLoginTest < ActionDispatch::IntegrationTest

  def setup
    @user = users(:foo)
  end

  test "login with invalid information" do
    get login_path
    assert_template 'sessions/new'
    post login_path, session: { email: "", password: "" }
    assert_template 'sessions/new'
    assert_not flash.empty?
    get root_path
    assert flash.empty?
  end

  test "login with valid information followed by logout" do
    get login_path
    post login_path, session: { email: @user.email, password: 'password' }
    assert is_logged_in?
    assert_redirected_to :projects
    follow_redirect!
    assert_template 'projects/index'
    assert_select "a[href=?]", login_path, count: 0
    assert_select "a[href=?]", logout_path
    ## Wait until we add user settings.
    # assert_select "a[href=?]", user_path(@user)
    delete logout_path
    assert_not is_logged_in?
    assert_redirected_to root_url
    # Simulate a user clicking logout in a second window.
    delete logout_path
    follow_redirect!
    assert_select "a[href=?]", login_path
    assert_select "a[href=?]", logout_path,      count: 0
    assert_select "a[href=?]", user_path(@user), count: 0
  end


  test "login with remembering" do
    cookies.delete('remember_token')
    log_in_as(@user, remember_me: '1')
    assert_not_nil cookies['remember_token']
    assert is_logged_in?
  end

  test "login without remembering" do
    cookies.delete('remember_token')
    log_in_as(@user, remember_me: '0')
    assert_nil cookies['remember_token']
    assert is_logged_in?
  end
end
