class ProjectPermissionSerializer < ActiveModel::Serializer
  # self.root = false
  attributes :project_id, :id, :user_name, :user_id, :user_email, 
    :can_view, :can_author, :can_annotate


  def user_email
    object.user.email
  end

  def user_name
    object.user.name
  end
end
