class ProjectFile < ActiveRecord::Base
  belongs_to :project
  belongs_to :creator, class_name: "User", foreign_key: :added_by
  has_many :comments, through: :comment_locations
  has_many :alternative_code
  

end
