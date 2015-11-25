class ProjectPermissionSerializer < ActiveModel::Serializer
  # self.root = false
  attributes :project_id, :id, :user_email, 
    :can_view, :can_author, :can_annotate
end
