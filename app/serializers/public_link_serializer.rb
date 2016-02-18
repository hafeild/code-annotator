class PublicLinkSerializer < ActiveModel::Serializer
  # self.root = false
  attributes :project_id, :id, :link_uuid, :name
end
