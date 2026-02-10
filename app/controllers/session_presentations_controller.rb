# frozen_string_literal: true

class SessionPresentationsController < ApplicationController
  def index
    @session_presentations = SessionPresentation.includes({ session: :meeting }, :document).ordered
  end
end
