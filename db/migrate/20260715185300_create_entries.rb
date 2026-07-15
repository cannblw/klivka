class CreateEntries < ActiveRecord::Migration[8.1]
  def change
    create_table :entries do |t|
      t.references :friend, null: false, foreign_key: true
      t.string :kind, null: false
      t.json :content

      t.timestamps
    end
  end
end
