# frozen_string_literal: true

module Auth
  class SessionsController < ApplicationController
    skip_before_action :require_login, only: [ :new, :create, :failure ]

    def new
    end

    def create
      user = User.find_or_create_from_omniauth(request.env["omniauth.auth"])
      session[:user_id] = user.id
      redirect_to root_path, notice: "Logged in as #{user.nickname}"
    end

    def destroy
      reset_session
      redirect_to root_path, notice: "Logged out"
    end

    def failure
      redirect_to root_path, alert: "Authentication failed: #{params[:message]}"
    end
  end
end
