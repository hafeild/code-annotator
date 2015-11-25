class ProjectPermission < ActiveRecord::Base
  belongs_to :project
  belongs_to :user

  # validates :user_id, presence: true
  validates :project_id, presence: true
  validates :can_author, inclusion: { in: [true, false] }
  validates :can_view, inclusion: { in: [true, false] }
  validates :can_annotate, inclusion: { in: [true, false] }

end
