class CreateVcardImports < ActiveRecord::Migration[8.1]
  def change
    create_table :vcard_imports do |t|
      t.references :user, null: false, foreign_key: { on_delete: :cascade }
      t.json :candidates, null: false
      t.json :selected_candidate_ids, null: false
      t.integer :rejected_count, null: false, default: 0
      t.datetime :expires_at, null: false
      t.timestamps
    end

    add_index :vcard_imports, :expires_at
    add_check_constraint :vcard_imports, "rejected_count >= 0", name: "vcard_imports_rejected_count_is_nonnegative"
  end
end
