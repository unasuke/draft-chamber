class CreateDocumentMaterialUploadedBies < ActiveRecord::Migration[8.1]
  def change
    create_table :document_material_uploaded_bies do |t|
      t.references :document_material, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true

      t.timestamps
    end
  end
end
