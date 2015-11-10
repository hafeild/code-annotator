class ProjectItem
  attr_accessor :project_file, :is_directory, :name

  def initialize(name="", project_file=nil)
    @project_file = project_file
    @is_directory = false
    @name = name
  end
end

class ProjectDirectory < ProjectItem
  attr_accessor :files

  def initialize(name="", project_file=nil)
    super(name, project_file)
    @is_directory = true
    @files = []
    @directories = {}

  end

  ## Breaks the path into two parts: the next directory and the
  ## remaining path.
  def breakPath(path)
    dividerIndex = path.index("/")
    if dividerIndex.nil?
      ["", path]
    else
      [path[0..dividerIndex], path[dividerIndex+1..-1]]
    end
  end

  def addSubFile(path, project_file)
    (nextPath, remainingPath) = breakPath(path)
    if remainingPath == "" and project_file.is_directory?
      @files << ProjectDirectory.new(nextPath, project_file)
      @directories[nextPath] = @files.last
    elsif nextPath == ""
      @files << ProjectItem.new(remainingPath, project_file)
    elsif @directories.has_key?(nextPath)
      @directories[nextPath].addSubFile(remainingPath, project_file)
    else
      raise "Found file that couldn't be added!! #{project_file.name}"
    end
  end
end

class Project < ActiveRecord::Base
  belongs_to :creator, class_name: "User", foreign_key: :created_by
  has_many :users, through: :project_permissions
  has_many :project_permissions
  has_many :project_files

  validates :created_by, presence: true
  validates :name, presence: true, length: {maximum: 255}

  def getFilesAsDirectories()
    dirs = ProjectDirectory.new()

    self.project_files.sort{|x,y| x.name <=> y.name}.each do |f|
      dirs.addSubFile(f.name, f)
    end

    dirs
  end
end
