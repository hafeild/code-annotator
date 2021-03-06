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

    ## Confirms the correct user.
    def correct_user
      @user = User.find(params[:id])
      redirect_to(root_url) unless current_user?(@user)
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

    ## Displays a JSON error.
    ## @param message (OPTIONAL) The message to display. The default JSONError
    ##                message is displayed if omitted.
    def render_error(message=nil)
      render json: JSONError.new(message), serializer: ErrorSerializer
    end

    ## Determines if the current user has the specified permissions to the 
    ## given project. 
    ## @param project_id The id of the project.
    ## @param permissions An array of permissions, e.g., [:can_view,:can_author]
    ## @param mode One of :all (all specified permissions must match) or
    ##             :any (any of the specified permissions must match).
    ## @return true if the user has all the given permissions for the project.
    def user_can_access_project(project_id, permissions, mode=:all)
      project_permissions = ProjectPermission.find_by(
        project_id: project_id, user_id: current_user.id)

      ## If the user has no permissions, it's a moot issue.
      return false if project_permissions.nil?

      ## Check if the user's permissions include the ones requested.
      checked = permissions.select{|p| project_permissions[p]}
      if mode == :all
        checked.size == permissions.size
      elsif mode == :any
        checked.size >= 1
      else
        @error = "Invalid mode specified in call to "+
            "user_can_access_project: #{mode}."
        false
      end
    end

    ## Deletes a project and all associated permissions, comments, files,
    ## and altcode. This will raise exceptions and can be used within a 
    ## transaction.
    ## @param project The project to delete.
    def delete_project(project)
      ## Remove all permissions.
      project.project_permissions.each do |permission|
        permission.destroy!
      end

      ## Remove all files.
      project.project_files.each do |file|
        delete_file(file)
      end

      ## Remove all comments.
      project.comments.each do |comment|
        delete_comment(comment)
      end

      ## Lastly, remove the project itself.
      project.destroy!
    end


    ## Deletes a file and all of its alt code. This will raise exceptions
    ## and can be used within a transaction.
    ## @param comment The project file to delete.
    ## @param destroy_subtree Whether to delete all subfiles of this file (if
    ##                        it's a directory). Default: false.
    def delete_file(file, delete_subtree=false)
      ## Delete all altcode.
      file.alternative_codes.each do |altcode|
        altcode.destroy!
      end

      ## Delete all comment locations.
      file.comment_locations.each do |comment_location|
        comment_location.destroy!
      end

      ## Remove the subtree if requested to do so.
      if delete_subtree
        file.sub_tree.each do |sub_file|
          delete_file(sub_file, true)
        end
      end

      file.destroy!
    end


    ## Deletes a comment and all of its locations. This will raise exceptions
    ## and can be used within a transaction.
    ## @param comment A Comment instance.
    def delete_comment(comment)
      ## Delete all comment locations.
      comment.comment_locations.each do |comment_location|
        delete_comment_location(comment_location)
      end
      comment.destroy!
    end

    ## Deletes a comment location. This will raise exceptions and can be used
    ## within a transaction.
    ## @param comment_location A CommentLocation instance.
    def delete_comment_location(comment_location)
      comment_location.destroy!
    end

    ## Checks if every key in a list of keys is present in the given hash.
    ## @param hash The hash map to consider.
    ## @param keys The list of keys to check.
    def has_keys?(hash, keys)
      keys.each do |key|
        unless hash.key?(key)
          return false
        end
      end
      true
    end

    ## Gets the value in the hash associated with the given key if it exists,
    ## otherwise returns the default.
    ## @param hash The hash.
    ## @param key The key.
    ## @param default The default to return if key is not in hash.
    def get_with_default(hash, key, default)
      hash.key?(key) ? hash[key] : default
    end

end
