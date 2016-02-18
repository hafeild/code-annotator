class ProjectsController < ApplicationController
  before_action :logged_in_user, except: [:show_public, :download_public]
  before_action :get_project, only: [:download]
  before_action :get_files, only: [:download]
  before_action :has_view_permissions, only: [:download]
  include FileCreationHelper
  
  def index
    @user = current_user

    @authoredProjects = @user.project_permissions.where({can_author: true}).
      map{|pp| pp.project}.sort{|x,y| x.name <=> y.name}

    @viewableProjects = @user.project_permissions.where({can_author: false,
      can_annotate: false, can_view: true}).map{|pp| pp.project}.
      sort{|x,y| x.name <=> y.name}

    @annotatableProjects = @user.project_permissions.where({can_author: false,
      can_annotate: true}).map{|pp| pp.project}.sort{|x,y| x.name <=> y.name}
  end

  ## Shows the project specified by the given link uuid -- as long as a project
  ## exists with the given uuid, it can be served. There are no permissions
  ## that need to be checked and the requester does not need to be logged in.
  def show_public
    success = false

    if params.key?(:link_uuid)
      public_link = PublicLink.find_by(link_uuid: params[:link_uuid])

      if(public_link)

        @project = public_link.project
        @project_permission = @project.project_permissions
        @is_public = true
        @project_id = "public/#{public_link.link_uuid}"
        success = true
      end
    end

    if success
      render :show
    else
      flash[:warning] = "That link provided is invalid."
      redirect_to :home
    end
  end

  ## Renders the given project as long as the user is logged in and has
  ## view permissions for the requested project.
  def show
    success = false

    if params.key?(:id)
      @project_permission = ProjectPermission.find_by(
        project_id: params[:id],
        user_id: current_user.id
      )
      @project = Project.find_by(id: params[:id])
      @is_public = false
      @project_id = @project.id
      success =(@project and @project_permission and @project_permission.can_view)
    end

    if success
      render :show
    else
      flash[:warning] = "That project does not exist or you do not have "+
        "permission to view it."
      redirect_to :projects
    end
  end

  def destroy
    redirect_to :root
  end

  ## Downloads files accessible via a public link.
  def download_public
    success = false

    if params.key?(:link_uuid)
      public_link = PublicLink.find_by(link_uuid: params[:link_uuid])

      if(public_link)

        @project = public_link.project
        get_files
        success = true
      end
    end

    if success
      download
    else
      flash[:warning] = "That link provided is invalid."
      redirect_to :home
    end
  end

  ## Downloads the specified files. The user must be logged in and have view
  ## permissions.
  def download
    if @files.size > 1 or (@files.size == 1 and @files.first.is_directory)
      files_by_name = get_files_by_name(@files).sort{|x,y| x <=> y}

      zip = Zip::OutputStream.write_buffer do |zip_stream|
        files_by_name.each do |name, file|
          zip_stream.put_next_entry name
          zip_stream.print file.content
        end
      end

      zip.rewind
      send_data zip.read, filename: "project.zip", type: "application/zip"

    elsif @files.size == 1
      file = @files.shift
      send_data file.content, filename: file.name, type: "text/plain"
    else
      render_error "No files specified."
    end
  end

  def create
    ## Extract parameters.
    name   = params[:project].fetch(:name, nil)
    files  = params[:project].fetch(:files, nil)
    batch  = params[:project].fetch(:batch, false)
    update = params[:project].fetch(:update, false)

    Rails.logger.debug ">>>>> files: #{files}"

    if (name.nil? and not batch) or (files.nil? and batch)
      flash[:danger] = "Missing parameters. Must include a project name or "+
        "files in batch mode."
    else
      begin
        ## Check if this is a batch project creation or not.
        if batch

          ## There should be one and only one zip file.
          if files.size != 1 or files.first.original_filename !~ /\.zip$/
            flash[:danger] = "Must provides exactly one zip file for batch mode."
          else
            projects = create_batch_projects files.first, update      

            unless projects
              flash[:danger] = "There was a problem creating the projects."
            end
          end
        ## It's just a one-off project creation.
        else
          project = create_new_project name, files

          unless project
            render_error "There was a problem creating the project."
          end
        end
      rescue => e
        flash[:danger] = "There was a problem creating the project: #{e.to_s}"
      end
    end

    redirect_to :projects, flash: {danger: flash.now[:danger]}
  end

  private
    def get_project
      @project = Project.find_by(id: params[:project_id])
    end

    def has_permissions(permissions)
      ## Only provide the file to the user if they have permissions to author.
      unless @project and user_can_access_project(@project.id, permissions)
        flash[:danger] = "This project may not exist or you do no have "+
          "permissions to view it."
        redirect_back_or root_url
      end
    end

    def has_author_permissions
      has_permissions [:can_author]
    end

    def has_view_permissions
      has_permissions [:can_view]
    end

    ## Makes a list of file ids and ensures that only files for the project are
    ## included.
    def get_files
      @file_ids = params[:files][:file_ids].split(/,/).map{|x| x.to_i}
      @files = []
      @file_ids.each do |id|
        file = ProjectFile.find_by(id: id)
        if file and file.project_id == @project.id
          @files << file
        else
          flash[:danger] = "Some files specified are not part of this project."
          redirect_back_or root_url
        end
      end
    end

    ## Creates a list of ProjectFiles in the order they should be zipped.
    def get_files_by_name(files)
      files_by_name = {} ## Will hold filename => ProjectFile mapping.
      files.each do |file|
        if file.is_directory
          files_by_name.merge!(get_files_by_name file.sub_tree)
        else
          files_by_name[file.path] = file
        end
      end
      files_by_name
    end
end
