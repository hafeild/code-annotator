class Project < ActiveRecord::Base
  belongs_to :creator, class_name: "User", foreign_key: :created_by
  has_many :users, through: :project_permissions
  has_many :project_permissions
  has_many :project_files
  has_many :comments



  validates :created_by, presence: true
  validates :name, presence: true, length: {maximum: 255}

  def getFilesAsDirectories()
    dirs = ProjectDirectory.new()

    self.project_files.sort{|x,y| x.name <=> y.name}.each do |f|
      dirs.addSubFile(f.name, f)
    end

    dirs
  end

  def altcode 
    all_altcode = []
    project_files.each{|file| all_altcode.concat(file.alternative_codes)}
    all_altcode
  end

  def root
    ProjectFile.find_by(project_id: id, directory_id: nil)
  end
end
