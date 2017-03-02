class Tag < ActiveRecord::Base
    belongs_to :user
    has_many :projects, through: :project_tags

    ## The tag text must exist and between 1 and 100 characters.
    validates :text, presence: true, length: {minmum: 1, maximum: 100}

    ## Tags must be unique by user (case insensitive).
    validates_uniqueness_of :text, :scope => :user_id, case_sensitive: false

    ## User must exist.
    validate :validate_user_id

    def validate_user_id
      if User.find_by(id: user_id).nil?
        errors.add(:user_id, "must be a valid user")
      end
    end
end
