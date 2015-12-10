class Api::FilesController < ApplicationController
  before_action :logged_in_user_api
  before_action :get_file, only: [:show, :destroy]
  before_action :get_project
  before_action :has_author_permissions, only: [:create_directory, :destroy]
  before_action :has_view_permissions, only: [:show, :download]

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
 
    dir_params = params.require(:directory).permit(:directory_id, :name)

    ## If no directory_id is given, attach this file to the root directory
    ## for this project.
    if not dir_params.key?(:directory_id) or dir_params[:directory_id].nil?
      dir_params[:directory_id] = @project.root.id
    end

    dir_params[:content]      = ""
    dir_params[:project_id]   = @project.id
    dir_params[:added_by]     = current_user.id
    dir_params[:size]         = 0
    dir_params[:is_directory] = true

    file = ProjectFile.create(dir_params)
    if file
       render json: file.id, serializer: SuccessWithIdSerializer
      return
    end

    
    render_error "Directory couldn't be created."
  end

  ## Retrieves the file and accompaning information (comment locations and
  ## altcode). This can be accessed by anyone with view permissions.
  def show
    render json: @file, serializer: FileSerializer, :root => "file"
  end

  ## Removes a file and all associated comment locations and altcode. If it's
  ## a directory, removes all subfiles and directories. The user must have
  ## author permissions. Root file may not be removed.
  def destroy
    error = nil

    if @file.directory_id.nil?
      error = "Cannot remove root directory. Delete the project, instead."
    else
      ActiveRecord::Base.transaction do
        delete_file(@file, true);
        render json: "", serializer: SuccessSerializer
        return
      end
      error = "Files could not be deleted."
    end

    render_error error
  end

  def download

    fileIds = params[:files][:file_ids].split(/,/)

    if fileIds.size > 1
      zip = Zip::OutputStream.write_buffer do |zipstream|
        fileIds.each do |fileId|
          file = ProjectFile.find_by(id: fileId)
          zipstream.put_next_entry file.name
          zipstream.print file.content
        end
      end

      zip.rewind
      send_data zip.read, filename: "project.zip", type: "application/zip"

    elsif fileIds.size == 1
      file = ProjectFile.find_by(id: fileIds.shift)
      send_data file.content, filename: file.name, type: "text/plain"
    end
  end

  def print
    render json: "", serializer: SuccessSerializer
  end

  private
    def get_file
      @file = ProjectFile.find_by(id: params[:id])
    end

    def get_project
      if @file
        @project = @file.project
      else
        @project = Project.find_by(id: params[:project_id])
      end
    end

    def has_permissions(permissions)
      ## Only provide the file to the user if they have permissions to author.
      unless @project and user_can_access_project(@project.id, permissions)
        render_error
      end
    end

    def has_author_permissions
      has_permissions [:can_author]
    end

    def has_view_permissions
      has_permissions [:can_view]
    end
end
