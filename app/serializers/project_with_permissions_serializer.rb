class ProjectWithPermissionsSerializer < ActiveModel::Serializer
  # self.root = false
  attributes :id, :name, :can_view, :can_author, :can_annotate

  def id
    object.project.id
  end


  def name
    object.project.name
  end
end
