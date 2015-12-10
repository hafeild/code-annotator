

class FilesController < ApplicationController
  before_action :logged_in_user

  MAX_PROJECT_SIZE_BYTES = 1024*1024 # 1MB
  MAX_PROJECT_SIZE_MB = MAX_PROJECT_SIZE_BYTES/1024/1024


  def create

    project = Project.find_by(id: params[:project_id])
    file = nil;


    ## Make sure the user has permissions to edit this project.
    if project and user_can_access_project(project.id, [:can_author])

      if params[:project_file][:files].size == 0
        flash.now[:danger] = "No files uploaded."
        redirect_to "/projects/#{project.id}", 
          flash: {danger: flash.now[:danger]}
        return
      end

      project_size = get_project_size(project)

      ActiveRecord::Base.transaction do
        tmp_file = nil

        parent_directory_id = project.root.id
        if params[:project_file].key? :directory_id
          parent_directory_id = params[:project_file][:directory_id]
        end

        params[:project_file][:files].each do |file_io|

          project_size += file_io.size
          if project_size > MAX_PROJECT_SIZE_BYTES
            flash.now[:danger] = "Error: couldn't save files -- Project size "+
              "exceeded #{MAX_PROJECT_SIZE_MB} MB."
            raise ActiveRecord::Rollback, 
              "Couldn't save file -- project size exceeded "+
              "#{MAX_PROJECT_SIZE_BYTES} bytes."
          end



          begin
            tmp_file = create_file(file_io, project.id, parent_directory_id)
          rescue => e
            ## DEBUG ONLY
            flash.now[:danger] = e.to_s
            raise ActiveRecord::Rollback, e.to_s
          end

          
          if not tmp_file.save
            flash.now[:danger] = "Error: couldn't save files."
            raise ActiveRecord::Rollback, "Couldn't save file!"
          end
        end

        file = tmp_file
      end

      if file.nil?
        redirect_url = "/projects/#{project.id}"
      else
        redirect_url = "/projects/#{project.id}##{file.id}"
      end

      if flash.now[:danger].nil?
        redirect_to redirect_url
      else 
        redirect_to redirect_url, flash: {danger: flash.now[:danger]}
      end
    else
      flash.now[:danger] = "Couldn't access project #{project.id}."
      redirect_to root_path, flash: {danger: flash.now[:danger]}
    end
  end


  private
    def create_file(file_io, project_id, parent_directory_id)
      # original_filename
      file_content = file_io.read
      file_info = CharlockHolmes::EncodingDetector.detect file_content
      
      raise "#{file_io.original_filename} is not a text file; only text files "+
        "may be uploaded." unless file_info[:type] == :text

      ## Convert everything to UTF-8.
      file_content = CharlockHolmes::Converter.convert file_content, 
        file_info[:encoding], 'UTF-8'

      ProjectFile.create!(project_id: project_id, content: file_content, 
        added_by: current_user.id, name: file_io.original_filename,
        size: get_file_size(file_content), directory_id: parent_directory_id)

    end

    def get_project_size(project)
      total_bytes = 0
      project.project_files.each do |file|
        total_bytes += file.size
      end
      total_bytes
    end

    def get_file_size(io)
      io.size * 8
    end
end