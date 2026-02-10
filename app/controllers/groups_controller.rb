# frozen_string_literal: true

class GroupsController < ApplicationController
  def index
    @groups = Group.includes(:parent).order(:acronym)
  end
end
