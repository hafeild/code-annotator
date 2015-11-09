class Api::FilesController < ApplicationController
  before_action :logged_in_user_api
  
  def index
    render json: "", serializer: SuccessSerializer
  end

  def update
    render json: "", serializer: SuccessSerializer
  end

  def create
    render json: "", serializer: SuccessSerializer
  end

  def show
    file = ProjectFile.find_by(id: params[:id])

    ## Only provide the file to the user if they have authorization to view
    ## it.
    if not file.nil? and user_can_access_project(file.project.id, [:can_view])
      render json: file, serializer: FileSerializer, :root => "file"
    else
      render json: JSONError.new, serializer: ErrorSerializer
    end
  end

  def destroy
    render json: "", serializer: SuccessSerializer
  end

  def download
    render json: "", serializer: SuccessSerializer
  end

  def print
    render json: "", serializer: SuccessSerializer
  end
end
