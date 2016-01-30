class ProjectCreationSuccessSerializer < ActiveModel::Serializer
  self.root = false
  attributes :success
  has_many :projects, serializer: ProjectMetadataSerializer

  def success
    true
  end

  def projects
    object[:projects]
  end
end