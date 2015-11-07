class Api::ProjectsController < ApplicationController
  before_action :logged_in_user_api

  def index
    render json: current_user.project_permissions, 
      each_serializer: ProjectPermissionSerializer, :root => "projects"
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
