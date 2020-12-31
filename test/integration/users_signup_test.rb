require 'test_helper'

class UsersSignupTest < ActionDispatch::IntegrationTest

  test "invalid signup information" do
    get signup_path
    assert_no_difference 'User.count' do
      post users_path, params: {
        user: { 
          name:  "",
          email: "user@invalid",
          password:              "foo",
          password_confirmation: "bar" 
        }
      }
    end
    assert_template 'users/new'
  end

  test "valid signup information" do
    get signup_path
    assert_difference 'User.count', 1 do
      post users_path, params: {
        user: { 
          name:  "Example User",
          email: "user@example.com",
          password:              "password",
          password_confirmation: "password" 
        }
      }
    end
    # assert_template 'users/show'
    # assert is_logged_in?
  end

  test "permissions tied to an email should be resolved on signup" do
    email = "user@example.com"
    pp = ProjectPermission.create!({user_email: email, 
      project_id: projects(:p1).id, can_view: true, can_author: false,
      can_annotate: false})
    get signup_path
    assert_difference 'User.count', 1 do
      post users_path, params: {
        user: { 
          name:  "Example User",
          email: email,
          password:              "password",
          password_confirmation: "password" 
        }
      }
    end

    assert ProjectPermission.find(pp.id).user_email.nil?
    assert ProjectPermission.find(pp.id).user == User.find_by(email: email)
    # assert_template 'users/show'
    # assert is_logged_in?
  end

end