class Comment < ActiveRecord::Base
  has_many :comment_locations
  has_many :project_files, through: :comment_locations
  belongs_to :project

  validates :project_id, presence: true, allow_nil: false
  validate :validate_project_id


  ## Checks that the project_id is valid.
  def validate_project_id
    if Project.find_by(id: project_id).nil?
      errors.add(:project_id, "must correspond to a valid project.")
    end
  end
end
