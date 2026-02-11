# frozen_string_literal: true

class DocumentMaterialsController < ApplicationController
  before_action :set_document

  def create
    @document_material = @document.document_material || @document.build_document_material

    uploaded_file = params[:file]
    @document_material.file.attach(uploaded_file)
    @document_material.assign_attributes(
      download_status: :completed,
      downloaded_at: Time.current,
      content_type: uploaded_file.content_type,
      filename: uploaded_file.original_filename,
      byte_size: uploaded_file.size,
      download_error: nil
    )

    if @document_material.save
      @document_material.document_material_uploaded_bys.create!(user: current_user)
      redirect_to @document, notice: "Material uploaded successfully."
    else
      render "documents/show", status: :unprocessable_entity
    end
  end

  def destroy
    @document.document_material&.destroy
    redirect_to @document, notice: "Material deleted successfully."
  end

  private

  def set_document
    @document = Document.find(params[:document_id])
  end
end
