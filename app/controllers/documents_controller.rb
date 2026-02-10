# frozen_string_literal: true

class DocumentsController < ApplicationController
  def index
    @pagy, @documents = pagy(Document.includes(:group).order(created_at: :desc))
  end
end
