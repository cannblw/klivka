class CreateDemoStates < ActiveRecord::Migration[8.1]
  def up
    create_table :demo_states do |t|
      t.string :key, null: false
      t.datetime :started_at, null: false
      t.datetime :last_activity_at, null: false

      t.timestamps
    end

    add_index :demo_states, :key, unique: true
    add_check_constraint :demo_states, "key = 'shared'", name: "demo_states_key_is_shared"
    add_check_constraint :demo_states,
      "last_activity_at >= started_at",
      name: "demo_states_activity_is_within_current_cycle"
  end


  def down
    drop_table :demo_states
  end
end
