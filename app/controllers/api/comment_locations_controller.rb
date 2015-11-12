class Api::CommentLocationsController < ApplicationController
  before_action :logged_in_user_api

  def create
    success = false
    error = nil

    comment = Comment.find_by(id: params[:comment_id])
    if comment and user_can_access_project(comment.project_id, [:can_annotate])

      if params.key?(:comment_location) and has_keys?(params[:comment_location],
            [:project_file_id, :start_line, :start_column, 
             :end_line, :end_column])

        comment_location = CommentLocation.create(comment_params(comment.id))
        if comment_location.valid? and comment_location.save
          render json: comment_location.id, serializer: SuccessWithIdSerializer
          success = true
        else
          error = "Couldn't save comment; ensure all fields are valid."
        end
      else
        error = "Not all required fields are present."
      end
    end

    unless success
      render_error error
    end
  end

  def destroy
    success = false
    error = nil

    comment_location = CommentLocation.find_by(id: params[:id])
    if comment_location and user_can_access_project(
        comment_location.comment.project.id, [:can_annotate])

      if comment_location.destroy
        render json: "", serializer: SuccessSerializer
        success = true
      else
        error = "Comment location couldn't be deleted."
      end

    end

    unless success
      render_error error
    end
  end

  private

    ## Defines valid comment location parameters.
    def comment_params(comment_id=nil)
      ps = params.require(:comment_location).permit(
        :project_file_id, :start_line, :start_column, :end_line, :end_column)
      unless comment_id.nil?
        ps[:comment_id] = comment_id
      end
      ps
    end


end

