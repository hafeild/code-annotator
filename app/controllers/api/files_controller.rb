class Api::FilesController < ApplicationController
  before_action :logged_in_user_api
  
  def index
    render json: "", serializer: SuccessSerializer
  end

  def update
    render json: "", serializer: SuccessSerializer
  end

  ## Creates a new directory. Can only be accessed by users with
  ## authoring permissions.
  def create_directory
    error = nil

    project = Project.find_by(id: params[:project_id])

    ## Only provide the file to the user if they have authorization to author
    ## it.
    if project and user_can_access_project(project.id, [:can_author])

      dir_params = params.require(:directory).permit(:directory_id, :name)

      ## If no directory_id is given, attach this file to the root directory
      ## for this project.
      if not dir_params.key?(:directory_id) or dir_params[:directory_id].nil?
        dir_params[:directory_id] = project.root.id
      end

      dir_params[:content]      = ""
      dir_params[:project_id]   = project.id
      dir_params[:added_by]     = current_user.id
      dir_params[:size]         = 0
      dir_params[:is_directory] = true

      file = ProjectFile.create(dir_params)
      if file
         render json: file.id, serializer: SuccessWithIdSerializer
        return
      end

      error = "Directory couldn't be created."
    end
    
    render_error error
  end

  ## Retrieves the file and accompaning information (comment locations and
  ## altcode). This can be accessed by anyone with view permissions.
  def show
    file = ProjectFile.find_by(id: params[:id])

    ## Only provide the file to the user if they have authorization to view it.
    if not file.nil? and user_can_access_project(file.project.id, [:can_view])
      render json: file, serializer: FileSerializer, :root => "file"
    else
      render_error
    end
  end

  ## Removes a file and all associated comment locations and altcode. If it's
  ## a directory, removes all subfiles and directories. The user must have
  ## author permissions. Root file may not be removed.
  def destroy
    error = nil
    file = ProjectFile.find_by(id: params[:id])

    ## Only provide the file to the user if they have authorization to author
    ## it.
    if not file.nil? and user_can_access_project(file.project.id, [:can_author])

      if file.directory_id.nil?
        error = "Cannot remove root directory. Delete the project, instead."
      else
        ActiveRecord::Base.transaction do
          delete_file(file, true);
          render json: "", serializer: SuccessSerializer
          return
        end
        error = "Files could not be deleted."
      end
    end
    render_error error
  end

  def download
    render json: "", serializer: SuccessSerializer
  end

  def print
    render json: "", serializer: SuccessSerializer
  end
end
