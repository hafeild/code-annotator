class SuccessSerializer < ActiveModel::Serializer
  self.root = false
  attributes :success

  def success
    true
  end
end
