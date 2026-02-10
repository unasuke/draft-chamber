# frozen_string_literal: true

class GroupsController < ApplicationController
  def index
    @pagy, @groups = pagy(Group.includes(:parent).order(:acronym))
  end
end
