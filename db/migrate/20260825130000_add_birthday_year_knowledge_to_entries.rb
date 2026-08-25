class AddBirthdayYearKnowledgeToEntries < ActiveRecord::Migration[8.1]
  class EntryRecord < ActiveRecord::Base
    self.table_name = "entries"
  end

  def up
    add_column :entries, :birthday_year_known, :boolean

    EntryRecord.where(type: "Entry::Birthday").update_all(birthday_year_known: true)

    add_check_constraint :entries,
      <<~SQL.squish,
        (type = 'Entry::Birthday' AND birthday_year_known IS NOT NULL)
        OR
        (type <> 'Entry::Birthday' AND birthday_year_known IS NULL)
      SQL
      name: "entries_birthday_year_knowledge_matches_type"
  end

  def down
    remove_check_constraint :entries, name: "entries_birthday_year_knowledge_matches_type"
    remove_column :entries, :birthday_year_known
  end
end
