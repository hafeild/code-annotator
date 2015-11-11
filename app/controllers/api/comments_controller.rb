class Api::CommentsController < ApplicationController
  before_action :logged_in_user_api

  def index
    ## Should be coming in as: projects/:project_id/comments
    file = nil
    if params.has_key?(:file_id)
      file = ProjectFile.find_by(id: params[:file_id])
    end
    project = Project.find_by(id: params[:project_id])
    if not project.nil? and user_can_access_project(project.id, [:can_view]) and
        (not params.has_key?(:file_id) or (params.has_key?(:file_id) and not file.nil?))
      if file.nil?
        comments = project.comments
      else
        comments = file.comments
      end
      render json: comments, each_serializer: CommentSerializer, 
        :root => "comments"
    else
      render json: JSONError.new, serializer: ErrorSerializer
    end
  end

  def update
    ## Should be coming in as: projects/:project_id/comments
    ## with the necessary fields.
    render json: "", serializer: SuccessSerializer
  end

  def create
    render json: "", serializer: SuccessSerializer
  end

  def show
    render json: "", serializer: SuccessSerializer
  end

  def destroy
    render json: "", serializer: SuccessSerializer
  end
end
