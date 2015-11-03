class User < ActiveRecord::Base
  has_many :projects, through: :project_permissions
  has_many :project_permissions
  has_many :created_projects, class_name: "Project", foreign_key: "created_by"
  
  ## Validate the password -- must be present and between 8--50 characters.
  has_secure_password
  validates :password, presence: true, 
            length: { minimum: 8, maximum: 50 }, allow_nil: true

  ## Uses BCrypt to salt/encrypt a password.
  def User.digest(string)
    cost = ActiveModel::SecurePassword.min_cost ? BCrypt::Engine::MIN_COST :
                                                  BCrypt::Engine.cost
    BCrypt::Password.create(string, cost: cost)
  end

  ## Creates a new random token.
  def User.new_token
    SecureRandom.urlsafe_base64
  end

  ## Adds a remember token to the database.
  def remember
    self.remember_token = User.new_token
    update_attribute(:remember_digest, User.digest(remember_token))
  end

  # Forgets a user (removes the remember token).
  def forget
    update_attribute(:remember_digest, nil)
  end

  private
    ## Converts email to all lower-case.
    def downcase_email
      self.email = email.downcase
    end

    ## Creates and assigns the activation token and digest.
    def create_activation_digest
      self.activation_token = User.new_token
      self.activation_digest = User.digest(activation_token)
    end
end
