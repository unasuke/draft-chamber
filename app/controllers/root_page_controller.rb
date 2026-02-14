# frozen_string_literal: true

class RootPageController < ApplicationController
  skip_before_action :require_login

  def index
  end
end
