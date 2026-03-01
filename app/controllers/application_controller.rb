# frozen_string_literal: true

class ApplicationController < ActionController::Base
  include Pagy::Method

  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  before_action :redirect_direct_origin_access
  before_action :require_login

  private

  def redirect_direct_origin_access
    return unless Rails.env.production?
    return unless ENV["CLOUDFRONT_ORIGIN_VERIFY"] == "true"
    return if request.headers["X-Origin-Verify"] == Rails.application.credentials.dig(:cloudfront, :origin_verify_secret)

    redirect_to URI.join("https://draft-chamber.unasuke.dev", request.fullpath).to_s,
      allow_other_host: true, status: :moved_permanently
  end

  def require_login
    redirect_to login_path, alert: "Please log in" unless current_user
  end

  def current_user
    @current_user ||= User.find_by(id: session[:user_id]) if session[:user_id]
  end

  helper_method :current_user
end
