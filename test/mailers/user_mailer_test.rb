require 'test_helper'

class UserMailerTest < ActionMailer::TestCase
  test "account_activation" do
    user = users(:foo)
    user.activation_token = User.new_token
    mail = UserMailer.account_activation(user)
    assert_equal "CodeAnnotator account activation", mail.subject
    assert_equal [user.email], mail.to
    assert_equal [ENV['FROM_EMAIL']], mail.from
    assert_match user.name,               mail.body.encoded
    assert_match user.activation_token,   mail.body.encoded
    assert_match CGI::escape(user.email), mail.body.encoded
  end

  test "email_verification" do
    user = users(:foo)
    user.activation_token = User.new_token
    mail = UserMailer.email_verification(user)
    assert_equal "CodeAnnotator email verification", mail.subject
    assert_equal [user.email], mail.to
    assert_equal [ENV['FROM_EMAIL']], mail.from
    assert_match user.name,               mail.body.encoded
    assert_match user.activation_token,   mail.body.encoded
    assert_match CGI::escape(user.email), mail.body.encoded
  end


  test "password_reset" do
    user = users(:foo)
    user.reset_token = User.new_token
    mail = UserMailer.password_reset(user)
    assert_equal "CodeAnnotator password reset", mail.subject
    assert_equal [user.email], mail.to
    assert_equal [ENV['FROM_EMAIL']], mail.from
    assert_match user.name,               mail.body.encoded
    assert_match user.reset_token,        mail.body.encoded
    assert_match CGI::escape(user.email), mail.body.encoded
  end
end
