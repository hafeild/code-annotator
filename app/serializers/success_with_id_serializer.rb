class SuccessWithIdSerializer < ActiveModel::Serializer
  self.root = false
  attributes :success, :id

  def success
    true
  end

  def id
    object
  end
end
