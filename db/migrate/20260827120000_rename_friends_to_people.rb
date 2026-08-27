class RenameFriendsToPeople < ActiveRecord::Migration[8.1]
  NAME_MAX_LENGTH = 255

  def up
    rename_table :friends, :people
    rename_column :entries, :friend_id, :person_id
    rename_column :interactions, :friend_id, :person_id
    rename_column :keep_in_touch_settings, :friend_id, :person_id
    rename_singleton_entry_indexes_to_person

    remove_check_constraint :people, name: :friends_name_is_within_maximum_length
    add_check_constraint :people, "length(name) <= #{NAME_MAX_LENGTH}", name: :people_name_is_within_maximum_length
  end

  def down
    remove_check_constraint :people, name: :people_name_is_within_maximum_length
    add_check_constraint :people, "length(name) <= #{NAME_MAX_LENGTH}", name: :friends_name_is_within_maximum_length

    rename_column :keep_in_touch_settings, :person_id, :friend_id
    rename_column :interactions, :person_id, :friend_id
    rename_column :entries, :person_id, :friend_id
    rename_singleton_entry_indexes_to_friend
    rename_table :people, :friends
  end

  private

  # SQLite's index rename emulation drops partial predicates, so recreate these indexes explicitly on both adapters.
  def rename_singleton_entry_indexes_to_person
    remove_index :entries, name: :index_entries_on_friend_id_for_birthday
    remove_index :entries, name: :index_entries_on_friend_id_for_first_met
    add_index :entries, :person_id, unique: true, where: "type = 'Entry::Birthday'", name: :index_entries_on_person_id_for_birthday
    add_index :entries, :person_id, unique: true, where: "type = 'Entry::FirstMet'", name: :index_entries_on_person_id_for_first_met
  end

  def rename_singleton_entry_indexes_to_friend
    remove_index :entries, name: :index_entries_on_person_id_for_birthday
    remove_index :entries, name: :index_entries_on_person_id_for_first_met
    add_index :entries, :friend_id, unique: true, where: "type = 'Entry::Birthday'", name: :index_entries_on_friend_id_for_birthday
    add_index :entries, :friend_id, unique: true, where: "type = 'Entry::FirstMet'", name: :index_entries_on_friend_id_for_first_met
  end
end
