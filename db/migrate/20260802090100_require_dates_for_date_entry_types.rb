class RequireDatesForDateEntryTypes < ActiveRecord::Migration[8.1]
  def change
    add_check_constraint :entries,
      <<~SQL.squish,
        (type IN ('Entry::Date', 'Entry::Birthday', 'Entry::FirstMet') AND entry_date IS NOT NULL)
        OR
        (type NOT IN ('Entry::Date', 'Entry::Birthday', 'Entry::FirstMet') AND entry_date IS NULL)
      SQL
      name: "entries_date_types_require_entry_date"
  end
end
