class CreateInteractions < ActiveRecord::Migration[8.1]
  def change
    create_table :interactions do |t|
      t.references :friend, null: false, foreign_key: true
      t.datetime :occurred_at, null: false
      t.string :contact_method
      t.text :note
      t.timestamps
    end

    add_index :interactions, [ :friend_id, :occurred_at ]

    add_check_constraint :interactions,
      "contact_method IS NULL OR contact_method IN ('call', 'message', 'video', 'in_person', 'other')",
      name: "interactions_contact_method_is_supported"
  end
end
