class AddEntryPositions < ActiveRecord::Migration[8.1]
  def change
    add_column :entries, :position, :integer, null: false, default: 0
    add_check_constraint :entries, "position >= 0", name: "entries_position_non_negative"
    add_index :entries, [ :friend_id, :position ]
  end
end
