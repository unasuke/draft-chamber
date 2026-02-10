# frozen_string_literal: true

class MeetingsController < ApplicationController
  def index
    @meetings = Meeting.recent
  end
end
