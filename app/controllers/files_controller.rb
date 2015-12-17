class FilesController < ApplicationController
  before_action :logged_in_user

  MAX_PROJECT_SIZE_BYTES = 1024*1024 # 1MB
  MAX_PROJECT_SIZE_MB = MAX_PROJECT_SIZE_BYTES/1024/1024


  def create

    project = Project.find_by(id: params[:project_id])
    last_file = nil;
    files_ignored = false


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

        parent_directory_id = project.root.id
        if params[:project_file].key? :directory_id
          parent_directory_id = params[:project_file][:directory_id]
        end

        params[:project_file][:files].each do |file_io|

          begin
            save_info = process_file(file_io, project.id, parent_directory_id)
            files_ignored ||= save_info[:files_ignored]

            last_file = save_info[:last_file]

            project_size += save_info[:size]
            if project_size > MAX_PROJECT_SIZE_BYTES
              flash.now[:danger] = "Error: couldn't save files -- Project "+
                "size exceeded #{MAX_PROJECT_SIZE_MB} MB."
              raise ActiveRecord::Rollback, 
                "Couldn't save file -- project size exceeded "+
                "#{MAX_PROJECT_SIZE_BYTES} bytes."
            end
          rescue => e
            Rails.logger.debug(e.to_s)
            Rails.logger.debug(e.backtrace)
            ## DEBUG ONLY
            flash.now[:danger] = e.to_s
            raise ActiveRecord::Rollback, e.to_s
          end
        end        
      end

      ## Let the user know if any files were ignored.
      if files_ignored
        flash[:warning] = "FYI, one or more non-text files were ignored."
      end

      ## Display the last loaded file.
      if last_file.nil? or last_file.id.nil?
        redirect_url = "/projects/#{project.id}"
      else
        redirect_url = "/projects/#{project.id}##{last_file.id}"
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
    def process_file(file_io, project_id, parent_directory_id)
      # original_filename

      ## Check if this is a zip or not.
      if file_io.original_filename =~ /\.zip$/
        process_zip_file file_io, project_id, parent_directory_id
      else
        create_file(file_io.read, file_io.original_filename, project_id,
          parent_directory_id, ignore_binary=true)
      end

    end

    def process_zip_file(file_io, project_id, parent_directory_id)
      save_data = {last_file: nil, size: 0, files_ignored: false}
      
      Zip::File.open(file_io.tempfile) do |zipfile|
        zipfile.each do |entry|
          next if entry.name =~ /(^|[\/])__MACOSX(\/|$)/

          if entry.directory?
            create_directories_in_path(project_id, parent_directory_id, 
              entry.name, treat_last_as_file=false)
          elsif entry.file?
            directory_id = create_directories_in_path(project_id, 
              parent_directory_id, entry.name)

            content = entry.get_input_stream.read

            cur_save_data = create_file(content, entry.name.split(/\//).last, 
              project_id, directory_id, ignore_binary=true)
            if cur_save_data[:last_file].nil?
              save_data[:files_ignored] = true
            else
              save_data[:last_file] = cur_save_data[:last_file]
              save_data[:size] += cur_save_data[:size]
            end
          end
        end
      end
      save_data
    end

    def create_file(content, name, project_id, parent_directory_id, ignore_binary=false)
      file_info = CharlockHolmes::EncodingDetector.detect content
      

      unless file_info[:type] == :text 
        if ignore_binary
          return {last_file: nil, size: 0, files_ignored: true}
        else
          raise "#{name} is not a text file; only text files may be uploaded."  
        end
      end

      ## Convert everything to UTF-8.
      content = CharlockHolmes::Converter.convert content, 
        file_info[:encoding], 'UTF-8'

      file = ProjectFile.create!(project_id: project_id, content: content, 
        added_by: current_user.id, name: name,
        size: get_file_size(content), directory_id: parent_directory_id)
      {last_file: file, size: file.size, files_ignored: false}
    end


    def create_directories_in_path(project_id, parent, path, treat_last_as_file=true)
      dirs = path.split(/\//)

      ## Remove the last file if necessary.
      dirs.pop if treat_last_as_file

      dirs.each do |dir_name|
        dir = ProjectFile.find_by(name: dir_name, directory_id: parent)
        unless dir
          dir = ProjectFile.create!(name: dir_name, directory_id: parent,
            content: nil, is_directory: true, added_by: current_user.id,
            project_id: project_id)
        end
        parent = dir.id
      end

      parent
    end

    def get_project_size(project)
      total_bytes = 0
      project.project_files.each do |file|
        total_bytes += file.size || 0
      end
      total_bytes
    end

    def get_file_size(io)
      io.size * 8
    end
end