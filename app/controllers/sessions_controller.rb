class SessionsController < ApplicationController
  def new
  end

  def create
    redirect_to :root
  end

  def destroy
    redirect_to :root
  end

end