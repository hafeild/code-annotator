class User < ActiveRecord::Base
  has_many :projects, through: :project_permissions
  has_many :project_permissions
  has_many :created_projects, class_name: "Project", foreign_key: "created_by"
  

end
