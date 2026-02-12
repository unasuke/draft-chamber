class AddProcessingStatusToDocumentMaterials < ActiveRecord::Migration[8.1]
  def change
    add_column :document_materials, :processing_status, :string, null: false, default: "not_applicable"
    add_column :document_materials, :processing_error, :text, null: false, default: ""
  end
end
