class ProjectMetadataSerializer < ActiveModel::Serializer
  attributes :id, :creator_email, :created_on, :name

  def creator_email
    object.creator.email
  end

  def created_on
    object.created_at.strftime("%d-%b-%Y")
  end
end
