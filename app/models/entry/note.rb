# == Schema Information
#
# Table name: entries
#
#  id                  :integer          not null, primary key
#  birthday_year_known :boolean
#  content             :json
#  entry_date          :date
#  position            :integer          default(0), not null
#  type                :string           not null
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  person_id           :integer          not null
#
# Indexes
#
#  index_entries_on_entry_date               (entry_date)
#  index_entries_on_person_id                (person_id)
#  index_entries_on_person_id_and_position   (person_id,position)
#  index_entries_on_person_id_for_birthday   (person_id) UNIQUE WHERE type = 'Entry::Birthday'
#  index_entries_on_person_id_for_first_met  (person_id) UNIQUE WHERE type = 'Entry::FirstMet'
#
# Foreign Keys
#
#  person_id  (person_id => people.id)
#
class Entry::Note < Entry
  self.vcard_import_property = :note
end
