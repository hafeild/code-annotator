class ProjectsController < ApplicationController
  before_action :logged_in_user
  before_action :get_project, only: [:download]
  before_action :get_files, only: [:download]
  before_action :has_view_permissions, only: [:download]
  
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

  def show
    success = false

    if params.key?(:id)
      @projectPermission = ProjectPermission.find_by(
        project_id: params[:id],
        user_id: current_user.id
      )
      @project = Project.find_by(id: params[:id])

      success =(@project and @projectPermission and @projectPermission.can_view)
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

  # Downloads the specified files.
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
