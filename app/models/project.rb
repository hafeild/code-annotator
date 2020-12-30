class Project < ActiveRecord::Base
  belongs_to :creator, class_name: "User", foreign_key: :created_by
  has_many :project_permissions
  has_many :users, through: :project_permissions
  has_many :project_files
  has_many :comments
  has_many :public_links
  has_many :project_tags
  has_many :tags, through: :project_tags

  validates :created_by, presence: true
  validates :name, presence: true, length: {maximum: 255}

  ## Returns only tags for the current user.
  def tagsFor(user)
    if user.nil?
      []
    else
      tags.select{|x| x.user_id == user.id}
    end
  end

  ## Returns all of the altcode for this project.
  def altcode 
    all_altcode = []
    project_files.each{|file| all_altcode.concat(file.alternative_codes)}
    all_altcode
  end

  ## Returns the root directory for this project.
  def root
    ProjectFile.find_by(project_id: id, directory_id: nil)
  end
end
