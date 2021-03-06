class Api::CommentsController < ApplicationController
  before_action :logged_in_user_api

  def index
    ## Should be coming in as: api/projects/:project_id/comments or
    ## api/projects/:project_id/files/:file_id/comments.
    file = nil
    if params.has_key?(:file_id)
      file = ProjectFile.find_by(id: params[:file_id])
    end
    project = Project.find_by(id: params[:project_id])
    if not project.nil? and user_can_access_project(project.id, [:can_view]) and
        (not params.has_key?(:file_id) or 
          (params.has_key?(:file_id) and not file.nil?))
      if file.nil?
        comments = project.comments
      else
        comments = file.comments
      end
      render json: comments, each_serializer: CommentSerializer, 
        :root => "comments"
    else
      render_error
    end
  end



  def update
    comment = Comment.find_by(id: params[:id])
    if comment.nil?
      render_error
      return
    end

    project = Project.find_by(id: comment.project_id)

    ## Make sure the user can annotate this project.
    if project.nil? or not user_can_access_project(project.id, [:can_annotate])
      render_error
      return
    end

    p = comment_params
    if not p.has_key?(:content)
      render_error("Error: not content provided to update.")
      return
    end

    if comment.update(content: p[:content])
      render json: "", serializer: SuccessSerializer
    else
      render_error("There was a problem updating the comment.")
    end
  end



  def create
    project = Project.find_by(id: params[:project_id])

    ## Make sure the user can annotate this project.
    if project.nil? or not user_can_access_project(project.id, [:can_annotate])
      render_error
      return
    end

    comment = Comment.create(comment_params(project.id, @current_user.id))
    if comment.valid? and comment.save
      render json: comment.id, serializer: SuccessWithIdSerializer
    else
      render_error "There was a problem saving the comment."
    end
  end



  def show
    comment = Comment.find_by(id: params[:id])

    ## Make sure the comment exists.
    if comment.nil?
      render_error
      return
    end

    ## Check the permissions.
    if user_can_access_project(comment.project.id, [:can_view])
      render json: comment, serializer: CommentSerializer, root: "comment"
    else
      render_error
    end
  end



  def destroy
    success = false
    comment = Comment.find(params[:id])

    if comment and user_can_access_project(comment.project_id, [:can_annotate])
      ## Destroy all comment locations, too.
      ActiveRecord::Base.transaction do
        delete_comment(comment)
        success = true
      end
    end

    if success
      render json: "", serializer: SuccessSerializer
    else
      render_error
    end
  end


  private

    ## Defines valid comment parameters.
    def comment_params(project_id=nil, created_by=nil)
      ps = params.require(:comment).permit(:content)
      ps[:project_id] = project_id
      ps[:created_by] = created_by
      ps
    end



end
