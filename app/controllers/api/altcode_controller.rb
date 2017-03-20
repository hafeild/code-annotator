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
    success = false
    error = nil

    project = Project.find_by(id: params[:project_id])
    if project and user_can_access_project(project.id, [:can_annotate])

      if params.key?(:altcode) and has_keys?(params[:altcode],
            [:file_id, :start_line, :start_column, :end_line, :end_column, 
             :content])

        file = ProjectFile.find_by(id: params[:altcode][:file_id])
        if file and file.project != project
          error = "The specified file is not part of the project."
          render_error
          return
        end

        altcode = AlternativeCode.new(altcode_params(@current_user.id))
        if altcode.valid? and altcode.save
          render json: altcode.id, serializer: SuccessWithIdSerializer
          success = true
        else
          error = "Couldn't save altcode; ensure all fields are valid."
        end
      else
        error = "Not all required fields are present."
      end
    end

    unless success
      render_error error
    end
  end

  def show
    altcode = AlternativeCode.find_by(id: params[:id])
    if altcode and user_can_access_project(altcode.project_file.project.id, 
        [:can_view])
      render json: altcode, serializer: AlternativeCodeSerializer, 
        :root => "altcode"
    else
      render_error
    end
  end

  def destroy
    success = false
    error = nil

    altcode = AlternativeCode.find_by(id: params[:id])
    if altcode and user_can_access_project(
        altcode.project_file.project.id, [:can_annotate])

      if altcode.destroy
        render json: "", serializer: SuccessSerializer
        success = true
      else
        error = "Altcode couldn't be deleted."
      end

    end

    unless success
      render_error error
    end
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
