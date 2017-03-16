class ProjectTag < ActiveRecord::Base
  belongs_to :tag
  belongs_to :project

  validates_uniqueness_of :tag_id, :scope => :project_id
  validates_uniqueness_of :project_id, :scope => :tag_id

  validate :validate_project_id
  validate :validate_tag_id
  validate :validate_project_permissions

  ## Checks that the project id is valid.
  def validate_project_id
    if Project.find_by(id: project_id).nil?
      errors.add(:project_id, "must be a valid project")
    end
  end
 
  ## Checks that the tag id is valid.
  def validate_tag_id
    if Tag.find_by(id: tag_id).nil?
      errors.add(:tag_id, "must be a valid tag")
    end
  end
 
  ## Checks that the user has permission to view/annotate/author this file.
  def validate_project_permissions
    permissions = ProjectPermission.find_by(user_id: tag.user.id, 
        project_id: project_id)
    if permissions.nil? or not (permissions.can_view or permissions.can_author \
        or permissions.can_annotate) 
      errors.add(:project_id,
        "must be a project the user associated with the tag can see")
    end
  end
  
end
