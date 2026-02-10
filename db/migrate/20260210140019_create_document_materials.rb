class CreateDocumentMaterials < ActiveRecord::Migration[8.1]
  def change
    create_table :document_materials do |t|
      t.references :document, null: false, foreign_key: true, index: { unique: true }
      t.string :content_type
      t.string :filename
      t.integer :byte_size
      t.string :download_status, default: "pending", null: false
      t.datetime :downloaded_at
      t.text :download_error

      t.timestamps
    end

    add_index :document_materials, :download_status
  end
end
