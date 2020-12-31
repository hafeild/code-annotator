ENV['RAILS_ENV'] ||= 'test'
require File.expand_path('../../config/environment', __FILE__)
require 'rails/test_help'

class ActiveSupport::TestCase
  # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
  fixtures :all

  # Add more helper methods to be used by all tests here...
  include ApplicationHelper

  # Returns true if a test user is logged in.
  def is_logged_in?
    !session[:user_id].nil?
  end

  # Logs in a test user.
  def log_in_as(user)
    session[:user_id] = user.id
  end 

  def log_in_as_integration(user, options={})
    password    = options[:password]    || 'password'
    remember_me = options[:remember_me] || '1'
    post login_path, params: { session: { email:       user.email,
                                password:    password,
                                remember_me: remember_me } }
  end


  private

    # Returns true inside an integration test.
    def integration_test?
      defined?(post_via_redirect)
    end
end
