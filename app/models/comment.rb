class Comment < ActiveRecord::Base
  has_many :comment_locations
  has_many :project_files, through: :comment_locations
  belongs_to :project
end
