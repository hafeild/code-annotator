module FileCreationHelper
  MAX_PROJECT_SIZE_BYTES = 1024*1024 # 1MB
  MAX_PROJECT_SIZE_MB = MAX_PROJECT_SIZE_BYTES/1024/1024

  ## A wrapper for ActionDispatch::Http::UploadedFile. Only allows some of
  ## the UploadedFile actions.
  class UploadedFileWrapper

    def initialize(uploaded_file: nil, filename: nil, content: nil)
      @uploaded_file = uploaded_file
      @original_filename = filename
      @content = content
    end

    def read
      if @uploaded_file
        @uploaded_file.read
      else
        @content
      end
    end

    def original_filename
      if @original_filename
        @original_filename
      elsif @uploaded_file
        @uploaded_file.original_filename
      else
        nil
      end
    end

    def size
      if @uploaded_file
        @uploaded_file.size
      elsif @content
        @content.size
      else
        0
      end
    end

    def tempfile
      if @uploaded_file
        @uploaded_file.tempfile
      else
        nil
      end
    end
  end

  ## Creates a new project and adds any files -- files can be regular or zip.
  ##
  ## @param name The name of the project.
  ## @param files A list of files to add to the project.
  ## @return The project file if successfully created; nil otherwise.
  def create_new_project(name, files=nil)
    ActiveRecord::Base.transaction do
      project = Project.create(name: name, created_by: current_user.id)
      ## Create the permissions that go along with it.
      ProjectPermission.create!(project_id: project.id,
        user_id: current_user.id, can_author: true, can_view: true,
        can_annotate: true)

      ## Create a new root directory for the project.
      ProjectFile.create!(name: "", is_directory: true, size: 0, 
        directory_id: nil, project_id: project.id, content: "", 
        added_by: current_user.id)

      unless files.nil?
        add_files_to_project files, project.id, project.root.id
        # flash.now[:error] = "ACK"
      end

      return project
    end
    return nil
  end

  ## Opens a zip file and for every first-level directory: creates a project
  ## with that folders name (unless update is true and a projects with that 
  ## name already exists) and adds all of the files and directories under that
  ## folder to the project. Skips __MACOSX directories and non-regular files.
  ##
  ## @param zip_file The file containing the projects information.
  ## @param update (Default: false). If true, then projects that already exist
  ##               with a first-level directory name will be updated, rather
  ##               than a new project with the same name being created.
  def create_batch_projects(zip_file, update=false)
    projects = []
    ## Holds all of the files associated with each project.
    files_by_project = Hash.new{|h,k| h[k] = []} 
    ## Holds all empty directories.
    empty_directories_by_project = Hash.new{|h,k| h[k] = Set.new}

    ## Unpack the files.
    Zip::File.open(zip_file.tempfile) do |zf|
      zf.each do |entry|
        next if entry.name =~ /(^|[\/])__MACOSX(\/|$)/
        path_parts = entry.name.split(/\//)
        project_name = path_parts[0]
        path = path_parts[1..-1].join('/')

        next if path_parts.size <= 1

        if entry.directory?
          empty_directories_by_project[project_name] << path

          ##create_directories_in_path(project_id, parent_directory_id, 
          ##  entry.name, treat_last_as_file=false)
        elsif entry.file?

          filename = path_parts[-1]
          dir_path = path_parts[1..-2].join('/')

          ## We don't need to worry about creating this directory since it 
          ## contains a file.
          empty_directories_by_project[project_name].delete?(dir_path)

          files_by_project[project_name] << UploadedFileWrapper.new(
            filename: "#{path}", 
            content: entry.get_input_stream.read
          )

        end
      end
    end

    ## Process each of the projects.
    files_by_project.each do |project_name, files|
      project = nil

      ## Check if any existing projects with this name are authorable by the
      ## current user.
      if update
        existing_projects = Project.joins(:users).where(
          projects: {name: project_name}, 
          project_permissions: {can_author: true}, 
          users: {id: current_user.id}
        )
      end

      # Create projects (or retrieve the old ones) and add files.
      if update and existing_projects.any?
        project = existing_projects.first
        add_files_to_project files, project.id, project.root.id
      else
        project = create_new_project project_name, files
      end

      ## Add any un-created directories.
      root_id = project.root.id
      empty_directories_by_project[project_name].each do |dir|
        create_directories_in_path project.id, root_id, dir
      end

      projects << project
    end

    projects
  end


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
        flash.now[:warning] = "FYI, one or more non-text files were ignored."
      end

      last_file
    else
      return -1
    end
  end

  ## Processes a file, either zip or regular, adding it to the given project
  ## under the specified directory. __MACOSX files and folders are ignored.
  ##
  ## @param file_io The file's IO stream.
  ## @param project_id The id of the project.
  ## @param parent_directory_id The id of the folder to add the zip's files to.
  ## return A simple hash with the fields: last_file (the ActiveRecord of the 
  ##        last file added), size, and files_ignored (true if any of the files 
  ##        were binary or otherwise ignored).
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

  ## Processes a zip file, adding all of the files within to the given project
  ## under the specified directory. __MACOSX files and folders are ignored.
  ##
  ## @param file_io The zip file's IO stream.
  ## @param project_id The id of the project.
  ## @param parent_directory_id The id of the folder to add the zip's files to.
  ## return A simple hash with the fields: last_file (the ActiveRecord of the 
  ##        last file added), size, and files_ignored (true if any of the files 
  ##        were binary or otherwise ignored).
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

  ## Creates a file in the given project under the given directory.
  ##
  ## @param content The content of the file.
  ## @param name The name of the file (not including path).
  ## @param project_id The id of the project to add the file to.
  ## @param parent_directory_id The id of the folder to add the file to.
  ## @param ignore_binary Whether to skip binary files with errors (false) or
  ##                      without (true). Default is false.
  ## return A simple hash with the fields: last_file (the ActiveRecord of the 
  ##        file added), size, and files_ignored (true if the file was binary).
  def create_file(content, name, project_id, parent_directory_id, 
                  ignore_binary=false)
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

    ## Create all the directories necessary for this file.
    parent_directory_id = create_directories_in_path(
      project_id, parent_directory_id, name)
    name = name.split(/\//)[-1]

    ## Create the file.
    file = ProjectFile.create!(project_id: project_id, content: content, 
      added_by: current_user.id, name: name,
      size: get_file_size(content), directory_id: parent_directory_id)
    {last_file: file, size: file.size, files_ignored: false}
  end


  ## Create each directory in the given path, attached at the given parent
  ## directory. Folders are assumed to be delimited by a single / character.
  ##
  ## @param project_id The id of the project.
  ## @param parent The id of the parent folder.
  ## @param path The path of directories to add.
  ## @param treat_last_as_file A flag indicating whether the last portion of
  ##                           the path should be treated as a folder (false) or
  ##                           as a file (true).
  ## @return The id of the last (deepest) directory in the path.
  def create_directories_in_path(project_id, parent, path, 
                                 treat_last_as_file=true)
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

  ## Calculates a project's size.
  ##
  ## @param project The project (ActiveRecord).
  ## @return The size of the project in bytes.
  def get_project_size(project)
    total_bytes = 0
    project.project_files.each do |file|
      total_bytes += file.size || 0
    end
    total_bytes
  end

  ## Calculates a file's size.
  ##
  ## @param content The content of the file -- can be a string or any object
  ##                with a size attribute/function that returns the number of
  ##                characters in the file.
  ## @return The size of the file in bytes.
  def get_file_size(content)
    content.size * 8
  end

end