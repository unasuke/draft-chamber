# frozen_string_literal: true

module Oauth
  class RegistrationsController < ApplicationController
    skip_before_action :require_login
    skip_forgery_protection

    # RFC 7591: OAuth 2.0 Dynamic Client Registration
    # POST /oauth/register
    def create
      redirect_uris = params[:redirect_uris]
      unless redirect_uris.is_a?(Array) && redirect_uris.any?
        return render json: {
          error: "invalid_client_metadata",
          error_description: "redirect_uris is required and must be a non-empty array"
        }, status: :bad_request
      end

      application = Doorkeeper::Application.new(
        name: params[:client_name] || "Unknown Client",
        redirect_uri: redirect_uris.join("\n"),
        confidential: params.fetch(:token_endpoint_auth_method, "none") != "none",
        scopes: params[:scope] || "mcp"
      )

      if application.save
        response_body = {
          client_id: application.uid,
          client_name: application.name,
          redirect_uris: redirect_uris,
          grant_types: [ "authorization_code" ],
          response_types: [ "code" ],
          token_endpoint_auth_method: application.confidential? ? "client_secret_post" : "none",
          scope: application.scopes.to_s
        }
        response_body[:client_secret] = application.plaintext_secret if application.confidential?

        render json: response_body, status: :created
      else
        render json: {
          error: "invalid_client_metadata",
          error_description: application.errors.full_messages.join(", ")
        }, status: :bad_request
      end
    end
  end
end
