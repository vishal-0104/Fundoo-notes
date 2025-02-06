class CreateNotes < ActiveRecord::Migration[8.0]
  def change
    create_table :notes do |t|
      t.string :title
      t.text :content
      t.string :color
      t.boolean :is_deleted
      t.boolean :is_archived
      t.references :user, null: false, foreign_key: true

      t.timestamps
    end
  end
end
