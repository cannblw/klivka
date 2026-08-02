class AddSingletonEntryTypeIndexes < ActiveRecord::Migration[8.1]
  def change
    add_index :entries, :friend_id,
      unique: true,
      name: "index_entries_on_friend_id_for_birthday",
      where: "type = 'Entry::Birthday'"

    add_index :entries, :friend_id,
      unique: true,
      name: "index_entries_on_friend_id_for_first_met",
      where: "type = 'Entry::FirstMet'"
  end
end
