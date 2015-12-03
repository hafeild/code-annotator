class AlternativeCodeSerializer < ActiveModel::Serializer
  # self.root = false
  attributes :id, :content, :start_line, :start_column, 
    :end_line, :end_column, :creator_email
  attribute :project_file_id, key: :file_id

  def creator_email
    object.creator.email
  end
end 