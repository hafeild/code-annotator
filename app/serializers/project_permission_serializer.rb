class ProjectPermissionSerializer < ActiveModel::Serializer
  # self.root = false
  attributes :project_id, :id, :user_email, 
    :can_view, :can_author, :can_annotate

  def user_email
    if object.user_email.nil?
      object.user.email
    else
      object.user_email
    end
  end
end
