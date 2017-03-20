class Api::FilesController < ApplicationController
  before_action :logged_in_user_api, except: [:show_public]
  before_action :get_file, only: [:update, :show, :show_public, :destroy]
  before_action :get_project, except: [:show_public]
  before_action :has_author_permissions, only: [:update, :create_directory, :destroy]
  before_action :has_view_permissions, only: [:show]

  def index
    render json: "", serializer: SuccessSerializer
  end

  def update
    begin
      file_params = params.require(:file).permit(:name, :directory_id)
    rescue
      render_error "Parameters must includ a file key."
      return
    end

    change_made = false
    name = file_params.fetch(:name, nil)
    directory_id = file_params.fetch(:directory_id, nil)

    ## First, check if the name needs updating.
    if not name.nil? and @file.name != name
      @file.name = name
      change_made = true
    end

    ## Check if the directory id needs changing.
    if not directory_id.nil? and @file.directory_id != directory_id
      @file.directory_id = directory_id
      change_made = true
    end

    if change_made
      begin
        @file.save!
        render json: @file.id, serializer: SuccessWithIdSerializer
      rescue Exception => e
        render_error e
      end
    else 
      render json: @file.id, serializer: SuccessWithIdSerializer
    end
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
    dir_params[:added_by]     = @current_user.id
    dir_params[:size]         = 0
    dir_params[:is_directory] = true

    file = ProjectFile.create(dir_params)
    if file
       render json: file.id, serializer: SuccessWithIdSerializer
      return
    end

    
    render_error "Directory couldn't be created."
  end

  ## Retrieves the file and accompanying information (comment locations and
  ## altcode) for public links.
  def show_public
    success = false

    if params.key?(:link_uuid)
      public_link = PublicLink.find_by(link_uuid: params[:link_uuid])

      success = public_link and @file.project_id == public_link.project_id
    end

    if success
      render json: @file, serializer: FileSerializer, :root => "file"
    else
      render_error
    end
  end

  ## Retrieves the file and accompanying information (comment locations and
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
