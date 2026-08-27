class AddArchivedAtToPeople < ActiveRecord::Migration[8.1]
  def change
    add_column :people, :archived_at, :datetime
    add_index :people, [ :user_id, :archived_at ]
  end
end
