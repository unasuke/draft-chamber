# frozen_string_literal: true

class MeetingsController < ApplicationController
  def index
    @pagy, @meetings = pagy(Meeting.recent)
  end
end
