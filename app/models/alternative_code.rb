class AlternativeCode < ActiveRecord::Base
  belongs_to :project_file
  belongs_to :creator, class_name: "User", foreign_key: :created_by
  
end
