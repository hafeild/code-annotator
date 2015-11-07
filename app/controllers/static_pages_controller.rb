class StaticPagesController < ApplicationController
  def home
    if logged_in?
      redirect_to :projects
    end
  end

  def information
  end
end
