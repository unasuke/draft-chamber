# frozen_string_literal: true

class SessionsController < ApplicationController
  def index
    @sessions = Session.includes(:meeting, :group).order(created_at: :desc)
  end
end
