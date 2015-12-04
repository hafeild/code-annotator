class ProjectFile < ActiveRecord::Base
  belongs_to :project
  belongs_to :creator, class_name: "User", foreign_key: :added_by
  has_many :comment_locations
  has_many :comments, through: :comment_locations
  has_many :alternative_codes
  belongs_to :project_file
  
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
end
