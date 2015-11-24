class ProjectsController < ApplicationController
  before_action :logged_in_user
  
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
end
