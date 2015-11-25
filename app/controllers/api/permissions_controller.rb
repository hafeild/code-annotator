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

  ## Requires view permissions for the project.
  def show
    success = false;
    error = "Resource not available."
    permissions = nil

    if params.key?(:id)
      permissions = ProjectPermission.find_by(id: params[:id])
      if permissions
        project = permissions.project
        success = (project and user_can_access_project(project.id, [:can_view]))
      end
    end

    if success
      render json: permissions, serializer: ProjectPermissionSerializer,
        root: "permissions"
    else
      render_error error
    end
  end

  ## Requires author permissions on the project.
  def update
    render json: "", serializer: SuccessSerializer
  end

  ## Requires author permissions on the project.
  def create
    render json: "", serializer: SuccessSerializer
  end

  ## Requires author permissions on the project.
  def destroy
    success = false;
    error = "Resource not available."
    permissions = nil

    if params.key?(:id)
      permissions = ProjectPermission.find_by(id: params[:id])
      if permissions
        project = permissions.project
        if project and user_can_access_project(project.id, [:can_author])
          permissions.destroy
          success = permissions.destroyed?
          error = "Error removing permissions." unless success
        end
      end
    end

    if success
      render json: "", serializer: SuccessSerializer
    else
      render_error error
    end
  end
end
