class SessionsController < ApplicationController
  def new
  end

  ## Log a user in.
  def create
    user = User.find_by(email: params[:session][:email].downcase)
    if user and user.authenticate(params[:session][:password])
      if user.activated?
        ## Log in.
        log_in user
        params[:session][:remember_me] == '1' ? remember(user) : forget(user)
        redirect_back_or :projects
      else
        message = "Account not activated."
        message += "Check your email for the activation link."
        flash[:warning] = message
        redirect_to root_url
      end
    else
      ## Error!
      flash.now[:danger] = 'Invalid email/password combination'
      render 'new'
    end
  end

  ## Log the user out (assuming they are logged in).
  def destroy
    log_out if logged_in? 
    redirect_to :root
  end

end