class Project < ActiveRecord::Base
  belongs_to :creator, class_name: "User", foreign_key: :created_by
  has_many :users, through: :project_permissions
  has_many :project_permissions

  validates :created_by, presence: true
  validates :name, presence: true
end
