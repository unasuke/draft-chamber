class CreateConvertedDocumentMaterials < ActiveRecord::Migration[8.1]
  def change
    create_table :converted_document_materials do |t|
      t.references :document_material, null: false, foreign_key: true
      t.integer :page_number, null: false
      t.string :content_type, null: false
      t.integer :byte_size, null: false
      t.text :extracted_text, null: false, default: ""

      t.timestamps
    end
  end
end
