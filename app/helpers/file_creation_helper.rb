module FileCreationHelper
  MAX_PROJECT_SIZE_BYTES = 1024*1024 # 1MB
  MAX_PROJECT_SIZE_MB = MAX_PROJECT_SIZE_BYTES/1024/1024

  ## Adds the given files to the project under parent_directory_id. This checks
  ## the size of the project along the way. If there are any issues, the DB
  ## is not updated.
  ## @param files A list of files to add.
  ## @param project_id The id of the project.
  ## @param parent_directory_id The id of the directory to add these files
  ##                            under. If nil, the root of the project is used.
  ## @return The last file added (nil if the last file to add wasn't added for
  ##       some reason); -1 if the user isn't authorized to view the project
  ##       or the project doesn't exist.
  def add_files_to_project(files, project_id, parent_directory_id)
    project = Project.find_by(id: project_id)
    last_file = nil;
    files_ignored = false

    parent_directory_id = project.root if parent_directory_id.nil?

    ## Make sure the user has permissions to edit this project.
    if project and user_can_access_project(project.id, [:can_author])

      if files.size == 0
        flash.now[:danger] = "No files uploaded."
        redirect_to "/projects/#{project.id}", 
          flash: {danger: flash.now[:danger]}
        return nil
      end

      project_size = get_project_size(project)

      ActiveRecord::Base.transaction do

        files.each do |file_io|

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
            flash.now[:danger] = e.to_s
            raise ActiveRecord::Rollback, e.to_s
          end
        end        
      end

      ## Let the user know if any files were ignored.
      if files_ignored
        flash[:warning] = "FYI, one or more non-text files were ignored."
      end

      last_file
    else
      return -1
    end
  end

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