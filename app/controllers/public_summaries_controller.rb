# frozen_string_literal: true

# Serves the shareable summary page. Unlike SummariesController this is readable
# without logging in, so that a summary URL can be handed to anyone.
class PublicSummariesController < ApplicationController
  skip_before_action :require_login

  layout "public_summary"

  def show
    @summary = Summary.find_by!(public_token: params[:public_token])
  end
end
