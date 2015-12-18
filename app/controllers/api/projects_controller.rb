class Api::ProjectsController < ApplicationController
  before_action :logged_in_user_api

  def index
    render json: current_user.project_permissions, 
      each_serializer: ProjectWithPermissionsSerializer, :root => "projects"
  end

  def update
    render json: "", serializer: SuccessSerializer
  end

  def create
    begin
      p = params.require(:project).permit(:name)
    rescue
      render_error "Missing parameters. Must include a project name."
      return
    end

    project = create_new_project p[:name]
    if project
      render json: project, serializer: SessionCreationSuccessSerializer
    else
      render_error "There was a problem creating the project."
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

    def create_new_project(name, files=nil)
      ActiveRecord::Base.transaction do
        project = Project.create(name: name, created_by: current_user.id)
        ## Create the permissions that go along with it.
        ProjectPermission.create!(project_id: project.id,
          user_id: current_user.id, can_author: true, can_view: true,
          can_annotate: true)
        #permissions.save!

        ## Create a new root directory for the project.
        ProjectFile.create!(name: "", is_directory: true, size: 0, 
          directory_id: nil, project_id: project.id, content: "", 
          added_by: current_user.id)
        
        return project
      end
      return nil
    end

    def create_batch_projects(name, file, update_if_project_exists=false)
    end



end
