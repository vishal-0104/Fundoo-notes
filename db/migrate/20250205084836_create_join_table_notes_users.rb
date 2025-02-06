class CreateJoinTableNotesUsers < ActiveRecord::Migration[8.0]
  def change
    create_join_table :notes, :users do |t|
      t.index [:note_id, :user_id]
      t.index [:user_id, :note_id]
    end
  end
end
