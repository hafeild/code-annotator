class Api::TagsController < ApplicationController
  before_action :logged_in_user_api
  before_action :get_tag, only: [:show, :destroy, :update]
  before_action :owns_tag, only: [:show, :destroy, :update]
  before_action :get_text, only: [:create, :update]

  ## Lists all tags for the logged in user.
  def index
    render json: @current_user.tags, 
      each_serializer: TagSerializer, :root => "tags"
  end

  ## Updates the name of the given tag.
  def update
    unless @text.nil?
      begin
        @tag.update!({text: @text})
        render json: @tag, serializer: TagSerializer, root: "tag"
      rescue
        render_error "There was a problem updating the tag."
      end
    else
      render_error "Only the text of a tag can be updated."
    end
  end

  ## Creates a new tag.
  def create
    unless @text.nil?
      begin
        tag = Tag.create!({text: @text, user: @current_user})
        render json: tag, serializer: TagSerializer, root: "tag"
      rescue Exception => e
        render_error "There was a problem creating the tag. #{e}"
      end
    else
      render_error "The text for the tag must be provided."
    end
  end

  ## Retrieves information about just this tag.
  def show
    render json: @tag, serializer: TagSerializer, root: "tag"
  end

  ## Removes the tag.
  def destroy
    begin
        @tag.project_tags.each do |project_tag|
          project_tag.destroy!
        end
        @tag.destroy!
        render json: "", serializer: SuccessSerializer
    rescue
        render_error "There was an error removing the tag!"
    end
  end



  private
    def get_tag
        @tag = Tag.find_by(id: params[:id])
        if @tag.nil?
            render_error "Tag does not exist."
        end
    end

    def owns_tag
        if @tag.user != @current_user
            render_error "Resource unavailable."
        end
    end 

    def get_text
      begin
        @text = params.require(:tag).require(:text)
        raise "To many parameters." if params[:tag].values.size > 1
      rescue
        render_error "Text for the tag must be provided."
      end
    end
end
