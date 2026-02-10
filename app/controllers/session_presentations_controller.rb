# frozen_string_literal: true

class SessionPresentationsController < ApplicationController
  def index
    @pagy, @session_presentations = pagy(SessionPresentation.includes({ session: :meeting }, :document).ordered)
  end
end
