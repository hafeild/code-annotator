class Api::ProjectsController < ApplicationController
  before_action :logged_in_user_api
  include FileCreationHelper

  def index
    render json: current_user.project_permissions, 
      each_serializer: ProjectWithPermissionsSerializer, :root => "projects"
  end

  def update
    render json: "", serializer: SuccessSerializer
  end


  def create

    ## Extract parameters.
    name   = params[:project].fetch(:name, nil)
    files  = params[:project].fetch(:files, nil)
    batch  = params[:project].fetch(:batch, false)
    update = params[:project].fetch(:update, false)

    if (name.nil? and not batch) or (files.nil? and batch)
      render_error "Missing parameters. Must include a project name or files "+
        "in batch mode."
      return
    end

    begin
      ## Check if this is a batch project creation or not.
      if batch

        ## There should be one and only one zip file.
        if files.size != 1 or files.first.original_filename !~ /\.zip$/
          render_error "Must provides exactly one zip file for batch mode."
          return
        end

        projects = create_batch_projects files.first, update      

        if projects
          ## TODO
          render json: {projects: projects}, 
            serializer: ProjectCreationSuccessSerializer
        else
          render_error "There was a problem creating the projects."
        end
      ## It's just a one-off project creation.
      else
        project = create_new_project name, files

        if project
          render json: {projects: [project]}, 
            serializer: ProjectCreationSuccessSerializer
        else
          render_error "There was a problem creating the project."
        end
      end
    rescue => e
      render_error "There was a problem creating the project: #{e.to_s}"+
        " #{e.backtrace.first(5).join("\n")}"
    end
  end


  def show
    render json: "", serializer: SuccessSerializer
  end


  ## In the future, perhaps only the creator should be able to fully remove
  ## the project? Or someone should be appointed an owner role and they must
  ## remove it?
  def destroy
    project = Project.find_by(id: params[:id])

    if project and user_can_access_project(project.id, [:can_author])

      ActiveRecord::Base.transaction do
        ## Remove the project and everything associated with it (permissions,
        ## files, comments, altcode).
        delete_project(project)

        render json: "", serializer: SuccessSerializer
        return
      end
      render_error "Could not remove project."
    end
    render_error "Resource not available."
  end

  private

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



end
