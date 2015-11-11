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
        render json: JSONError.new("You are not logged in."), 
               serializer: ErrorSerializer
      end
    end

    ## A JSON error class.
    class JSONError
      attr_accessor :error

      def initialize(error=nil)
        error = error.nil? ? "Resource not available." : error
        @error = error
      end
    end


    ## Determines if the current user has the specified permissions to the 
    ## given project. 
    ## @param project_id The id of the project.
    ## @param permissions An array of permissions, e.g., [:can_view,:can_author]
    ## @return true if the user has all the given permissions for the project.
    def user_can_access_project(project_id, permissions)
      project_permissions = ProjectPermission.find_by(
        project_id: project_id, user_id: current_user.id)

      ## If the user has no permissions, it's a moot issue.
      return false if project_permissions.nil?

      ## Check if the user's permissions include the ones requested.
      checked = permissions.select{|p| project_permissions[p]}
      checked.size == permissions.size
    end
end
