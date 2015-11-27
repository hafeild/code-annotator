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
    altcode = AlternativeCode.find_by(id: params[:id])
    if altcode.nil?
      render_error
      return
    end

    project = altcode.project_file.project

    ## Make sure the user can annotate this project.
    if project.nil? or not user_can_access_project(project.id, [:can_annotate])
      render_error
      return
    end

    p = altcode_params

    if altcode.update(p)
      render json: "", serializer: SuccessSerializer
    else
      render_error("There was a problem updating the altcode.")
    end
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


  private

    ## Defines valid comment parameters.
    def altcode_params(created_by=nil)
      p = params.require(:altcode).permit(
        :start_line, :start_column, :end_line, :end_column, :content
      )
      if params[:altcode].key?(:file_id)
        p[:project_file_id] = params[:altcode][:file_id]
      end

      unless created_by.nil?
        p[:created_by] = created_by
      end

      p
    end
end
