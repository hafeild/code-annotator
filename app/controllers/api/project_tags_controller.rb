class Api::ProjectTagsController < ApplicationController
  before_action :logged_in_user_api
  before_action :get_project
  before_action :has_project_permissions
  before_action :get_tag, only: [:create, :destroy]
  before_action :get_project_tag, only: [:destroy]
  before_action :owns_tag, only: [:create, :destroy]
  before_action :get_text, only: [:create]

  ## Lists all tags for given project.
  def index
    render json: @project.tags, 
      each_serializer: TagSerializer, :root => "tags"
  end

  ## Creates a new tag.
  def create
    ActiveRecord::Base.transaction do
      begin
        if @tag.nil?
          @tag = Tag.create!({text: @text, user: @current_user})
        end

        project_tag = ProjectTag.create!({tag: @tag, project: @project})
        render json: @tag, serializer: TagSerializer,
          root: "tag"
      rescue Exception => e
        render_error "There was a problem creating the tag: #{e}."
      end
    end
  end


  ## Removes the tag.
  def destroy
    begin
      @project_tag.destroy!
      render json: "", serializer: SuccessSerializer
    rescue
      render_error "There was an error removing the tag."
    end
  end



  private
    def get_project
      @project = Project.find_by(id: params[:project_id])
    end


    def has_project_permissions
      unless @project and user_can_access_project(@project.id, 
            [:can_view, :can_author, :can_annotate], :any)
        render_error "Insufficient permissions for this project."
      end         
    end

    def get_tag
      @tag = nil
      if params.has_key? :tag_id
        @tag = Tag.find_by(id: params[:tag_id])
        if @tag.nil?
          render_error "Tag does not exist."
        end
      end
    end

    def get_project_tag
      if @tag.nil?
        render_error "Tag id must be specified."
      else
        @project_tag = ProjectTag.find_by(
          tag_id: @tag.id, project_id: @project.id)
        if @project_tag.nil? 
          render_error "The given tag is not associated with this project."
        end
      end
    end

    def owns_tag
        if not @tag.nil? and @tag.user.id != @current_user.id
            render_error "Resource unavailable."
        end
    end 

    def get_text
      @text = nil
      if @tag.nil?
        begin
          @text = params.require(:tag).require(:text)
          raise "To many parameters." if params[:tag].size > 1
        rescue
          render_error "Text for a new tag must be provided."
        end
      end
    end
end
