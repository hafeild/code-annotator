class Api::ProjectsController < ApplicationController
  before_action :logged_in_user_api

  def index
    render json: current_user.project_permissions, 
      each_serializer: ProjectPermissionSerializer, :root => "projects"
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

    p[:created_by] = current_user.id

    ActiveRecord::Base.transaction do
      project = Project.create(p)
      if project.valid? and project.save!
        ## Create the permissions that go along with it.
        permissions = ProjectPermission.create(project_id: project.id,
          user_id: current_user.id, can_author: true, can_view: true,
          can_annotate: true)
        permissions.save!

        render json: project, serializer: SessionCreationSuccessSerializer
        # render json: project.id, serializer: SuccessWithIdSerializer
        return
      end
    end

    render_error "There was a problem creating the project."
  end

  def show
    render json: "", serializer: SuccessSerializer
  end

  def destroy
    render json: "", serializer: SuccessSerializer
  end
end
