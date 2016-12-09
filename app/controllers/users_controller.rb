class UsersController < ApplicationController
  before_action :set_user, only: [:show, :destroy, :follows]
  before_action :verify_ownership, only: [:destroy]

  def show
  end

  def edit
    if params[:game].blank?
      redirect_to(settings_path, alert: "Invalid request.")
      return
    end

    g = Game.find_by(shortname: params[:game])
    if g.nil?
      redirect_to(settings_path, alert: "Invalid game.")
      return
    end

    result = g.enable_permalink_redirectors
    if !result
      redirect_to(settings_path, alert: "There was an issue enabling permalink redirectors for #{g}. Please try again.")
      return
    end

    redirect_to(settings_path, notice: "Permalink redirectors enabled for #{g}!")
  end

  def destroy
    if params[:destroy_runs] == '1'
      current_user.runs.destroy_all
    end
    current_user.destroy
    auth_session.invalidate!
    redirect_to root_path, alert: "Your account has been deleted. Go have fun outside :)"
  end

  def follows
    render partial: "shared/follows"
  end

  private

  def set_user
    @user = User.find_by(name: params[:user]) || not_found
  end

  def verify_ownership
    unless @user == current_user
      render :unauthorized, status: 401
    end
  end
end
