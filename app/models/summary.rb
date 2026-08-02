# frozen_string_literal: true

class Summary < ApplicationRecord
  UNKNOWN_CLIENT_NAME = "unknown"

  has_secure_token :public_token, length: 24

  belongs_to :session, optional: true
  belongs_to :user
  belongs_to :oauth_application, class_name: "Doorkeeper::Application", optional: true

  validates :title, presence: true, length: { maximum: 255 }
  validates :body, presence: true
  validates :meeting_number, presence: true
  validates :client_name, presence: true

  scope :recent, -> { order(created_at: :desc) }
  scope :linked, -> { where.not(session_id: nil) }

  def orphaned?
    session_id.nil?
  end

  def public_url
    if ENV["APP_HOST"].present?
      url_helpers.public_summary_url(public_token: public_token, host: ENV["APP_HOST"], protocol: "https")
    else
      url_helpers.public_summary_url(public_token: public_token, host: "localhost:3000", protocol: "http")
    end
  end

  private

  def url_helpers
    Rails.application.routes.url_helpers
  end
end
