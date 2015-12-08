class EmailVerificationsController < ApplicationController
  def edit
    user = User.find_by(email: params[:email])
    if user && !user.activated? && user.authenticated?(:activation, params[:id])
      user.activate
      log_in user
      flash[:success] = "Email verified!"
      redirect_to :projects
    else
      flash[:danger] = "Invalid activation link #{user.activated}; #{user.authenticated?(:activation, params[:id])}"
      redirect_to root_url
    end
  end
end
