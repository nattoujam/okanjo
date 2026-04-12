class HomeController < ApplicationController
  def index
    redirect_to new_group_path
  end
end
