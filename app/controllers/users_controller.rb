class UsersController < ApplicationController
  before_action :logged_in_user, only: [:edit, :update]
  before_action :correct_user,   only: [:edit, :update]

  def new
    @user = User.new
  end

  def create
    @user = User.new(user_params)
    @user.activated = false
    if @user.save
        #log_in @user
        @user.send_activation_email

        ## Take care of previous permissions for this user's email that were 
        ## saved prior to signup.
        ProjectPermission.where({user_email: @user.email}).each do |pp|
          pp.update({user_id: @user.id, user_email: nil})
        end

        #flash[:success] = "Thanks for signing up!"
        flash[:success] = "Please check your email to activate your account."
        redirect_to root_url
    else
        render 'new'
    end
  end

  def destroy
    redirect_to :root
  end

  def update
    @user = User.find(params[:id])
    ## Authenticate password.
    if params.key?(:user) and params[:user].key?(:current_password) and
        @user.authenticate(params[:user][:current_password])
      if @user.update_attributes(user_params)
        flash[:success] = "Profile updated"
      else
        flash[:danger] = "Please try again."
      end
    else
      flash[:danger] = "Could not authenticate. Please try again."
    end

    redirect_to edit_user_path(current_user)
  end

  def edit
    @user = User.find(params[:id])
  end

  private

    def user_params
      params.require(:user).permit(:name, :email, :password,
                                   :password_confirmation)
    end

    # Before filters

    # Confirms a logged-in user.
    def logged_in_user
      unless logged_in?
        store_location
        flash[:danger] = "Please log in."
        redirect_to login_url
      end
    end
end