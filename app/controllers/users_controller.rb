class UsersController < ApplicationController

  def new
    @user = User.new
  end

  def create
    @user = User.new(user_params)
    if @user.save
        log_in @user
        # @user.send_activation_email
        flash[:success] = "Thanks for signing up!"
        # flash[:success] = "Please check your email to activate your account."
        redirect_to root_url
    else
        render 'new'
    end
  end

  def destroy
    redirect_to :root
  end

  def update
    redirect_to :root
  end

  def edit
  end

  private

    def user_params
      params.require(:user).permit(:name, :email, :password,
                                   :password_confirmation)
    end

    # Before filters

    # Confirms the correct user.
    def correct_user
      @user = User.find(params[:id])
      redirect_to(root_url) unless current_user?(@user)
    end

end