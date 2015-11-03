class CommentLocation < ActiveRecord::Base
  belongs_to :comment
  belongs_to :project_file
end
