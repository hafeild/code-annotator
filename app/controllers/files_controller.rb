class FilesController < ApplicationController
  before_action :logged_in_user

  ## Log a user in.
  def create
    project = Project.find_by(id: params[:project_id])
    file = nil;

    ## Make sure the user has permissions to edit this project.
    if project and user_can_access_project(project.id, [:can_view])

      Rails.logger.debug("Number of files: #{params[:project_file][:files].size}")

      ActiveRecord::Base.transaction do
        tmp_file = nil

        params[:project_file][:files].each do |file_io|
          tmp_file = create_file(file_io, project.id)
          unless tmp_file.save
            flash.now[:danger] = "Error: couldn't save files."
            raise "Couldn't save file!"
          end
        end

        file = tmp_file
      end

      if file.nil?
        redirect_to "/projects/#{project.id}"
      else
        redirect_to "/projects/#{project.id}##{file.id}"
      end
    else
      flash.now[:danger] = "Couldn't access project #{project.id}."
      redirect_to :root_path
    end
  end


  private
    def create_file(file_io, project_id)
      # original_filename
      ProjectFile.create(project_id: project_id, content: file_io.read, 
        added_by: current_user.id, name: file_io.original_filename)
    end
end