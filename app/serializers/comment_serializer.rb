class CommentSerializer < ActiveModel::Serializer
  # self.root = false
  attributes :id, :content
  has_many :comment_locations, key: :locations, 
    serializer: CommentLocationSerializer
end