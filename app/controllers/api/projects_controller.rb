class Api::ProjectsController < ApplicationController
  before_action :logged_in_user_api
  include FileCreationHelper

  def index
    render json: current_user.project_permissions, 
      each_serializer: ProjectWithPermissionsSerializer, :root => "projects"
  end

  def update
    render json: "", serializer: SuccessSerializer
  end


  def create

    ## Extract parameters.
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
    project = Project.find_by(id: params[:id])

    if project and user_can_access_project(project.id, [:can_author])

      ActiveRecord::Base.transaction do
        ## Remove the project and everything associated with it (permissions,
        ## files, comments, altcode).
        delete_project(project)

        render json: "", serializer: SuccessSerializer
        return
      end
      render_error "Could not remove project."
    end
    render_error "Resource not available."
  end

  private

    ## Creates a new project and adds any files -- files can be regular or zip.
    ##
    ## @param name The name of the project.
    ## @param files A list of files to add to the project.
    ## @return The project file if successfully created; nil otherwise.
    def create_new_project(name, files=nil)
      ActiveRecord::Base.transaction do
        project = Project.create(name: name, created_by: current_user.id)
        ## Create the permissions that go along with it.
        ProjectPermission.create!(project_id: project.id,
          user_id: current_user.id, can_author: true, can_view: true,
          can_annotate: true)

        ## Create a new root directory for the project.
        ProjectFile.create!(name: "", is_directory: true, size: 0, 
          directory_id: nil, project_id: project.id, content: "", 
          added_by: current_user.id)

        unless files.nil?
          add_files_to_project files, project.id, project.root.id
          # flash.now[:error] = "ACK"
        end

        return project
      end
      return nil
    end





end
