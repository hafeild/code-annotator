class CommentSerializer < ActiveModel::Serializer
  # self.root = false
  attributes :id, :content, :creator_email
  has_many :comment_locations, key: :locations, 
    serializer: CommentLocationSerializer
  def creator_email
    object.creator.email
  end
end