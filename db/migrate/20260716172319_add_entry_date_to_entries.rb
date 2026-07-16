class AddEntryDateToEntries < ActiveRecord::Migration[8.1]
  def change
    add_column :entries, :entry_date, :date
    add_index :entries, :entry_date
  end
end
