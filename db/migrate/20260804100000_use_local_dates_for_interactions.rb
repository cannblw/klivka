class UseLocalDatesForInteractions < ActiveRecord::Migration[8.1]
  class MigrationInteraction < ActiveRecord::Base
    self.table_name = "interactions"
  end

  def up
    add_column :interactions, :occurred_on, :date
    MigrationInteraction.reset_column_information
    MigrationInteraction.find_each do |interaction|
      interaction.update_columns(occurred_on: interaction.occurred_at.to_date)
    end

    change_column_null :interactions, :occurred_on, false
    remove_index :interactions, [ :friend_id, :occurred_at ]
    remove_column :interactions, :occurred_at
    add_index :interactions, [ :friend_id, :occurred_on ]
  end

  def down
    add_column :interactions, :occurred_at, :datetime
    MigrationInteraction.reset_column_information
    MigrationInteraction.find_each do |interaction|
      date = interaction.occurred_on
      interaction.update_columns(occurred_at: Time.utc(date.year, date.month, date.day))
    end

    change_column_null :interactions, :occurred_at, false
    remove_index :interactions, [ :friend_id, :occurred_on ]
    remove_column :interactions, :occurred_on
    add_index :interactions, [ :friend_id, :occurred_at ]
  end
end
