class Api::PermissionsController < ApplicationController
  before_action :logged_in_user_api
  
  ## If the requester is authorized, returns all of the permissions associated
  ## with the requested project. The requested must have view permissions on
  ## the project to see who it's shared with.
  def index
    success = false;
    error = "Resource not available."
    project = nil

    if params.key?(:project_id)
      project = Project.find_by(id: params[:project_id])
      success = (project and user_can_access_project(project.id, [:can_view]))
    end

    if success
      render json: project.project_permissions, 
        each_serializer: ProjectPermissionSerializer
    else
      render_error error
    end
  end

  ## Requires view permissions for the project.
  def show
    success = false;
    error = "Resource not available."
    permissions = nil

    if params.key?(:id)
      permissions = ProjectPermission.find_by(id: params[:id])
      if permissions
        project = permissions.project
        success = (project and user_can_access_project(project.id, [:can_view]))
      end
    end

    if success
      render json: permissions, serializer: ProjectPermissionSerializer,
        root: "permissions"
    else
      render_error error
    end
  end

  ## Requires author permissions on the project.
  def update
    success = false;
    error = "Resource not available."
    permissions = nil

    if params.key?(:id) and params.key?(:permissions)
      permissions = ProjectPermission.find_by(id: params[:id])
      if permissions
        if permissions.user and permissions.user == current_user
          error = "User permissions may not be modified."
        else
          project = permissions.project
          if project and user_can_access_project(project.id, [:can_author])

            p = params.require(:permissions).permit(
              :can_author, :can_view, :can_annotate).to_h

            ## Authors get full permissions.
            if get_with_default(p, 'can_author', false)
              p['can_view']     = true
              p['can_annotate'] = true
            ## Annotators get at least viewing and annotation permissions.
            elsif get_with_default(p, 'can_annotate', false)
              p['can_view']     = true
            end
             
            Rails.logger.debug "p: #{p.to_json}; "+
              "can_annotate: #{get_with_default(p, :can_annotate, permissions.can_annotate)}, "+
              "can_author: #{get_with_default(p, :can_author, permissions.can_author)}"

            ## Make sure that can_view is not being taken away from a user with
            ## authoring or annotation permissions.
            if p.key?('can_view') and not p['can_view']
                (get_with_default(p, 'can_annotate', permissions.can_annotate) or
                 get_with_default(p, 'can_author', permissions.can_author))
                Rails.logger.debug "Hello -- ILLEGAL STATE REACHED!"
                error = "Illegal state of permissions: you cannot revoke "+
                  "viewing permissions from an author or annotator."
            else
              success = permissions.update(p)
              error = "Error updating permissions." unless success
            end
          end
        end
      end
    end

    if success
      render json: permissions, serializer: ProjectPermissionSerializer,
        root: "permissions"
    else
      render_error error
    end
  end

  ## Requires author permissions on the project. Can include either a user email
  ## or user id.
  def create
    success = false;
    error = "Resource not available."
    permissions = nil

    if params.key?(:project_id) and params.key?(:permissions)
      project = Project.find_by(id: params[:project_id])
      target_user = nil
      user_needs_placeholder = false

      if params[:permissions].key?(:user_id)
        target_user = User.find_by(id: params[:permissions][:user_id])
      elsif params[:permissions].key?(:user_email)
        target_user = User.find_by(email: params[:permissions][:user_email])
        user_needs_placeholder = true unless target_user
      else
        error = "No user specified."
      end

      if project and (target_user or user_needs_placeholder)

        if target_user and target_user == current_user
          error = "User permissions may not be modified."
        elsif project and user_can_access_project(project.id, [:can_author])

          p = params.require(:permissions).permit(
            :can_author, :can_view, :can_annotate)

          ## Decide whether the user_id or user_email field will be used.
          if target_user
            p[:user_id] = target_user.id
          else
            p[:user_email] = params[:permissions][:user_email]
          end

          ## Authors get full permissions.
          if get_with_default(p, :can_author, false)
            p[:can_view]     = true
            p[:can_annotate] = true
          ## Annotators get at least viewing and annotation permissions.
          elsif get_with_default(p, :can_annotate, false)
            p[:can_view]     = true
            p[:can_author]   = false
          else
            p[:can_view]     = true
            p[:can_author]   = false
            p[:can_annotate] = false
          end

          p[:project_id] = project.id

          begin
            permissions = ProjectPermission.create(p)
          rescue
          end
          error = "Error updating permissions." unless permissions
        end
      else
        ## DEBUG
        #error = "project missing or (target_user missing or user_needs_placeholder false)"
      end
    else
      ## DEBUG
      #error = "project_id or permissions missing"
    end

    if permissions
      render json: permissions, serializer: ProjectPermissionSerializer,
        root: "permissions"
    else
      render_error error
    end
  end

  ## Requires author permissions on the project.
  def destroy
    success = false;
    error = "Resource not available."
    permissions = nil

    if params.key?(:id)
      permissions = ProjectPermission.find_by(id: params[:id])
      if permissions
        project = permissions.project
        if project and user_can_access_project(project.id, [:can_author])
          permissions.destroy
          success = permissions.destroyed?
          error = "Error removing permissions." unless success
        end
      end
    end

    if success
      render json: "", serializer: SuccessSerializer
    else
      render_error error
    end
  end

end
