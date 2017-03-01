class Tag < ActiveRecord::Base
    belongs_to :user
    has_many :projects, through: :project_tags
end
