class Api::ProjectsController < ApplicationController
  before_action :logged_in_user_api
  before_action :get_project, only: [:update, :destroy]
  before_action :can_update_project, only: [:update, :destroy]
  before_action :get_new_name, only: [:update]

  include FileCreationHelper

  def index
    render json: @current_user.project_permissions, 
      each_serializer: ProjectWithPermissionsSerializer, :root => "projects"
  end

  ## A project can have it's name changed.
  def update
    @project.name = @new_name
    begin
      @project.save!
      render json: "", serializer: SuccessSerializer
    rescue
      render_error "There was a problem saving the new project name."
    end
  end


  def create

    ## Extract parameters.
    begin
      params.require(:project)
    rescue
      render_error "Missing parameters. Must include a 'project' parameter with "+
        "subparameters 'name' or 'files' in batch mode."
      return
    end

    name   = params[:project].fetch(:name, nil)
    files  = params[:project].fetch(:files, nil)
    batch  = params[:project].fetch(:batch, false)
    update = params[:project].fetch(:update, false)

    if (name.nil? and not batch) or (files.nil? and batch)
      render_error "Missing parameters. Must include a project name or files "+
        "in batch mode."
      return
    end

    begin
      ## Check if this is a batch project creation or not.
      if batch

        ## There should be one and only one zip file.
        if files.size != 1 or files.first.original_filename !~ /\.zip$/
          render_error "Must provides exactly one zip file for batch mode."
          return
        end

        projects = create_batch_projects files.first, update      

        if projects
          ## TODO
          render json: {projects: projects}, 
            serializer: ProjectCreationSuccessSerializer
        else
          render_error "There was a problem creating the projects."
        end
      ## It's just a one-off project creation.
      else
        project = create_new_project name, files

        if project
          render json: {projects: [project]}, 
            serializer: ProjectCreationSuccessSerializer
        else
          render_error "There was a problem creating the project."
        end
      end
    rescue => e
      render_error "There was a problem creating the project: #{e.to_s}" #+
        # " #{e.backtrace.first(5).join("\n")}"
    end
  end


  def show
    render json: "", serializer: SuccessSerializer
  end


  ## In the future, perhaps only the creator should be able to fully remove
  ## the project? Or someone should be appointed an owner role and they must
  ## remove it?
  def destroy
    begin
      ActiveRecord::Base.transaction do
        ## Remove the project and everything associated with it (permissions,
        ## files, comments, altcode).
        delete_project(@project)

        render json: "", serializer: SuccessSerializer
      end
    rescue
      render_error "Could not remove project."
    end
  end

  private
  
    def get_project
      @project = Project.find_by(id: params[:id])
      if @project.nil?
        render_error "Invalid project id."
      end
    end

    def can_update_project
      unless @project and user_can_access_project(@project.id,
            [:can_author], :all)
        render_error "Insufficient permissions for this project."
      end
    end 

    def can_view_project
      unless @project and user_can_access_project(@project.id,
            [:can_author, :can_view, :can_annotate], :any)
        render_error "Insufficient permissions for this project."
      end
    end 

    def get_new_name
     @new_name = nil
      begin
        @new_name = params.require(:project).require(:name)
        raise "To many parameters." if params[:project].values.size > 1
      rescue Exception => e
        render_error "A 'project/name' field must be provided. #{e}"
      end
    end
end
