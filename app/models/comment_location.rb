class CommentLocation < ActiveRecord::Base
  belongs_to :comment
  belongs_to :project_file

  validates :comment_id, presence: true, allow_nil: false
  validates :project_file_id, presence: true, allow_nil: false
  validates :start_line, presence: true, allow_nil: false
  validates :start_column, presence: true, allow_nil: false
  validates :end_line, presence: true, allow_nil: false
  validates :end_column, presence: true, allow_nil: false

  validate :validate_comment_id, :validate_file_id, :validate_project

  ## Checks that the comment id is valid.
  def validate_comment_id
    if Comment.find_by(id: comment_id).nil?
      errors.add(:comment_id, "must be a valid comment")
    end
  end

  ## Checks that the file id is valid.
  def validate_file_id
    file = ProjectFile.find_by(id: project_file_id)
    if file.nil? 
      errors.add(:project_file_id, "must be a valid file")
    end
  end

  ## Checks that the comment and file are associated with the same project.
  def validate_project
    file = ProjectFile.find_by(id: project_file_id)
    comment = Comment.find_by(id: comment_id)
    if file.project.id != comment.project.id
      errors.add(:project_file_id, 
        "must be part of the same project as the comment")
    end
  end
end
