class FilesController < ApplicationController
  before_action :logged_in_user
  include FileCreationHelper

  def create
    project_id = params[:project_id]
    parent_directory_id = params[:project_file].key?(:directory_id) ? \
          params[:project_file][:directory_id] : nil

    last_file = add_files_to_project(params[:project_file][:files],
        project_id, parent_directory_id)
        

    if last_file == -1
      flash.now[:danger] = "Couldn't access project #{project_id}."
      redirect_to root_path, flash: {danger: flash.now[:danger]}
    else
      ## Display the last loaded file.
      if last_file.nil? or last_file.id.nil?
        redirect_url = "/projects/#{project_id}"
      else
        redirect_url = "/projects/#{project_id}##{last_file.id}"
      end

      if flash.now[:danger].nil?
        redirect_to redirect_url
      else 
        redirect_to redirect_url, flash: {danger: flash.now[:danger]}
      end
    end
  end


end