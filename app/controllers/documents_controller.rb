# frozen_string_literal: true

class DocumentsController < ApplicationController
  def index
    @documents = Document.includes(:group).order(created_at: :desc)
  end
end
