class FilesController < ApplicationController
  before_action :logged_in_user

  MAX_PROJECT_SIZE_BYTES = 1024*1024 # 1MB
  MAX_PROJECT_SIZE_MB = MAX_PROJECT_SIZE_BYTES/1024/1024

  ## Log a user in.
  def create
    project = Project.find_by(id: params[:project_id])
    file = nil;

    ## Make sure the user has permissions to edit this project.
    if project and user_can_access_project(project.id, [:can_view])

      if params[:project_file][:files].size == 0
        flash.now[:danger] = "No files uploaded."
        redirect_to "/projects/#{project.id}"
        return
      end

      project_size = get_project_size(project)

      ActiveRecord::Base.transaction do
        tmp_file = nil

        params[:project_file][:files].each do |file_io|
          tmp_file = create_file(file_io, project.id)
          project_size += tmp_file.size
          if project_size > MAX_PROJECT_SIZE_BYTES
            flash.now[:danger] = "Error: couldn't save files -- Project size "+
              "exceeded #{MAX_PROJECT_SIZE_MB} MB."
            raise "Couldn't save file -- project size exceeded "+
              "#{MAX_PROJECT_SIZE_BYTES} bytes."
          elif tmp_file.save
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
      file_content = file_io.read
      ProjectFile.create(project_id: project_id, content: file_content, 
        added_by: current_user.id, name: file_io.original_filename,
        size: get_file_size(file_content))
    end

    def get_project_size(project)
      total_bytes = 0
      project.project_files.each do |file|
        total_bytes += file.size
      end
      total_bytes
    end

    def get_file_size(file_content)
      file_content.size * 8
    end
end