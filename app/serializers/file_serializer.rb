class FileSerializer < ActiveModel::Serializer
  # self.root = false
  attributes :id, :name, :content
  has_many :comments, serializer: CommentSerializer
  has_many :alternative_codes, key: :altcode, 
    serializer: AlternativeCodeSerializer

  def comments
    object.comments.uniq
  end
end
