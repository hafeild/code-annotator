class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception
  include SessionsHelper
  include ApplicationHelper

  private

    ## Confirms a logged-in user.
    def logged_in_user
      unless logged_in?
        store_location
        flash[:danger] = "Please log in."
        redirect_to login_url
      end
    end

    ## For the JSON API; confirms if a user is logged in, if not,
    ## returns an error message.
    def logged_in_user_api
      unless logged_in?
        render json: JSONError.new("You are not logged in."), serializer: ErrorSerializer
      end
    end

    ## A JSON error class.
    class JSONError
      attr_accessor :error

      def initialize(error="Resource not available.")
        @error = error
      end
    end
end
