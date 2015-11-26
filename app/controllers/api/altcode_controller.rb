class Api::AltcodeController < ApplicationController
  before_action :logged_in_user_api
  
  def index
    ## Should be coming in as: api/projects/:project_id/altcode or
    ## api/projects/:project_id/files/:file_id/altcode.
    file = nil
    if params.has_key?(:file_id)
      file = ProjectFile.find_by(id: params[:file_id])
    end
    project = Project.find_by(id: params[:project_id])
    if not project.nil? and user_can_access_project(project.id, [:can_view]) and
        (not params.has_key?(:file_id) or 
          (params.has_key?(:file_id) and not file.nil?))
      if file.nil?
        altcode = project.altcode
      else
        altcode = file.alternative_codes
      end
      render json: altcode, each_serializer: AlternativeCodeSerializer, 
        :root => "altcode"
    else
      render_error
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
