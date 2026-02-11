# frozen_string_literal: true

module Admin
  class BaseController < ApplicationController
    before_action :require_admin

    private

    def require_login
      redirect_to main_app.login_path, alert: "Please log in" unless current_user
    end

    def require_admin
      redirect_to main_app.root_path, alert: "You are not authorized to access this page" unless current_user&.admin?
    end
  end
end
