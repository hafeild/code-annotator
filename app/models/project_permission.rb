class ProjectPermission < ActiveRecord::Base
  belongs_to :project
  belongs_to :user

  validates :user_id, presence: true
  validates :project_id, presence: true
  validates :can_author, presence: true
  validates :can_view, presence: true
  validates :can_annotate, presence: true

end
