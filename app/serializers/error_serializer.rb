class ErrorSerializer < ActiveModel::Serializer
  self.root = false
  attributes :error

  def error
    object.error
  end
end