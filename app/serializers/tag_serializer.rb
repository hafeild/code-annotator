class TagSerializer < ActiveModel::Serializer
  # self.root = false
  attributes :id, :text
  has_many :projects, serializer: ProjectMetadataSerializer
end
