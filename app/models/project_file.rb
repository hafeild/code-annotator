class ProjectFile < ActiveRecord::Base
  belongs_to :project
  belongs_to :creator, class_name: "User", foreign_key: :added_by
  has_many :comment_locations
  has_many :comments, through: :comment_locations
  has_many :alternative_codes
  validate :validate_name_uniqueness
  
  ## Checks if this name is unique within its directory.
  def validate_name_uniqueness
    unless ProjectFile.where(directory_id: directory_id, name: name).empty?
      errors.add(:name, "must be unique within a folder; please "+
        "change \"#{name}\" to something different.")
    end
  end

  ## Lists all of the files and directories that are children of this directory.
  ## Will return [] if this is a file or has no children. Files and directories
  ## are listed alphabetically, with directories coming before all files.
  def sub_tree
    files = ProjectFile.where(directory_id: id)
    files = files.nil? ? [] : files 

    files.sort{|x,y| 
      if x.is_directory and not y.is_directory
        -1
      elsif not x.is_directory and y.is_directory
        1
      else
        x.name <=> y.name
      end
    }
  end

  def parent_directory
    root? ? nil : ProjectFile.find(directory_id)
  end

  def root?
    directory_id.nil?
  end

  def path
    if is_directory
      root? ? "" : "#{parent_directory.path}#{name}/"
    else
      "#{parent_directory.path}#{name}"
    end
  end
end
