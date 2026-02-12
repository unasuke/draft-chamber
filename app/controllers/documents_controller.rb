# frozen_string_literal: true

class DocumentsController < ApplicationController
  def index
    @pagy, @documents = pagy(Document.includes(:group, :document_material).order(created_at: :desc))
  end

  def show
    @document = Document.includes(document_material: { converted_document_materials: { file_attachment: :blob } }).find(params[:id])
    @document_material = @document.document_material || @document.build_document_material
  end
end
