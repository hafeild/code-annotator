class PublicLink < ActiveRecord::Base
  belongs_to :project

  validates :project_id, presence: true, allow_nil: false
  validates :link_uuid, presence: true, uniqueness: {case_sensitive: true}
  validate :validate_project_id


  ## Checks that the project_id is valid.
  def validate_project_id
    if Project.find_by(id: project_id).nil?
      errors.add(:project_id, "must correspond to a valid project.")
    end
  end
end
