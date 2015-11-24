class SessionCreationSuccessSerializer < ActiveModel::Serializer
  self.root = false
  attributes :success, :id, :creator_email, :created_on, :name

  def success
    true
  end

  def creator_email
    object.creator.email
  end

  def created_on
    object.created_at.strftime("%d-%b-%Y")
  end
end