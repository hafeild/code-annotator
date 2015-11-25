class Api::PermissionsController < ApplicationController
  before_action :logged_in_user_api
  
  ## If the requester is authorized, returns all of the permissions associated
  ## with the requested project. The requested must have view permissions on
  ## the project to see who it's shared with.
  def index
    success = false;
    error = "Resource not available."
    project = nil

    if params.key?(:project_id)
      project = Project.find_by(id: params[:project_id])
      success = (project and user_can_access_project(project.id, [:can_view]))
    end

    if success
      render json: project.project_permissions, 
        each_serializer: ProjectPermissionSerializer
    else
      render_error error
    end
  end

  def update
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
