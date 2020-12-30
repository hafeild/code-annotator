class Api::PublicLinksController < ApplicationController
  before_action :logged_in_user_api
  before_action :get_public_link, except: [:index, :create]
  before_action :get_project
  before_action :has_author_permissions
  before_action :get_name, only: [:create, :update]

  ## These operations are only available to those who can author.

  ## Generates a new public link for the specified project.
  def create
    foundUnusedUUID = false
    begin
      ## Keep looping until we find an unused uuid.
      until foundUnusedUUID
        uuid = SecureRandom.uuid

        ActiveRecord::Base.transaction do
          if PublicLink.find_by({link_uuid: uuid}).nil?
            public_link = PublicLink.create!({
              project_id: @project.id, link_uuid: uuid, name: @name})
            render json: public_link, serializer: PublicLinkSerializer,
              root: "public_link"
            foundUnusedUUID = true
          end
        end
      end
    rescue => e
      render_error "Error saving record: #{e}"
    end
  end


  ## List all of the public links associated with this project. 
  def index
    render json: @project.public_links, each_serializer: PublicLinkSerializer
  end


  ## Lists the details for the given public link.
  def show
    render json: @public_link, serializer: PublicLinkSerializer,
      root: "public_link"
  end


  ## Updates a public link, namely it's name.
  def update
    unless @name.nil?
      begin
        @public_link.update!({name: @name})
        render json: @public_link, serializer: PublicLinkSerializer,
          root: "public_link"
      rescue
        render_error "There was a problem updating the public link."
      end
    else
      render_error "Only the name of a public link can be updated."
    end
  end


  ## Revokes the given public link.
  def destroy
    begin
      @public_link.destroy!
      render json: "", serializer: SuccessSerializer
    rescue
      render_error "Error removing permissions."
    end
  end


  private

    def get_public_link
        if params.key? :id
            @public_link = PublicLink.find_by({id: params[:id]})
        end

        unless @public_link
            render_error
        end
    end

    def get_project
      if @public_link
        @project = @public_link.project
      elsif params.key? :project_id
        @project = Project.find_by(id: params[:project_id])
      else
        render_error
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

    def get_name
      begin
        @name = params.require(:public_link).require(:name)
        raise "To many parameters." if params[:public_link].values.size > 1
      rescue
        render_error "A name must be provided."
      end
    end
end
