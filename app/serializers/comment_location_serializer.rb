class CommentLocationSerializer < ActiveModel::Serializer
  # self.root = false
  attributes :id, :start_line, :start_column, :end_line, :end_column
  attribute :project_file_id, key: :file_id

end