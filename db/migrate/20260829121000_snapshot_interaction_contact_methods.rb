class SnapshotInteractionContactMethods < ActiveRecord::Migration[8.1]
  LEGACY_METHODS = {
    "call" => { names: { "en" => "Call", "es" => "Llamada" }, icon: [ "material_icons", "call" ] },
    "message" => { names: { "en" => "Message", "es" => "Mensaje" }, icon: [ "material_icons", "chat" ] },
    "video" => { names: { "en" => "Video", "es" => "Videollamada" }, icon: [ "material_icons", "videocam" ] },
    "in_person" => { names: { "en" => "In person", "es" => "En persona" }, icon: [ "material_icons", "groups" ] },
    "other" => { names: { "en" => "Other", "es" => "Otro" }, icon: [ "material_icons", "more_horiz" ] }
  }.freeze

  class MigrationInteraction < ActiveRecord::Base
    self.table_name = "interactions"
    belongs_to :person, class_name: "SnapshotInteractionContactMethods::MigrationPerson"
  end

  class MigrationPerson < ActiveRecord::Base
    self.table_name = "people"
    belongs_to :user, class_name: "SnapshotInteractionContactMethods::MigrationUser"
  end

  class MigrationUser < ActiveRecord::Base
    self.table_name = "users"
  end

  def up
    add_column :interactions, :contact_method_name, :string
    add_column :interactions, :contact_method_icon_library, :string
    add_column :interactions, :contact_method_icon_name, :string

    MigrationInteraction.reset_column_information
    MigrationInteraction.includes(person: :user).where.not(contact_method: nil).find_each do |interaction|
      definition = LEGACY_METHODS.fetch(interaction.contact_method)
      locale = interaction.person.user.locale.to_s
      interaction.update_columns(
        contact_method_name: definition.fetch(:names).fetch(locale, definition.dig(:names, "en")),
        contact_method_icon_library: definition.fetch(:icon).first,
        contact_method_icon_name: definition.fetch(:icon).last
      )
    end

    remove_check_constraint :interactions, name: "interactions_contact_method_is_supported"
    remove_column :interactions, :contact_method

    add_check_constraint :interactions,
      "contact_method_name IS NULL OR length(contact_method_name) BETWEEN 1 AND 255",
      name: "interactions_contact_method_name_length"
    add_check_constraint :interactions,
      "contact_method_icon_library IS NULL OR length(contact_method_icon_library) BETWEEN 1 AND 255",
      name: "interactions_contact_method_icon_library_length"
    add_check_constraint :interactions,
      "contact_method_icon_name IS NULL OR length(contact_method_icon_name) BETWEEN 1 AND 255",
      name: "interactions_contact_method_icon_name_length"
    add_check_constraint :interactions,
      "(contact_method_icon_library IS NULL AND contact_method_icon_name IS NULL) OR " \
        "(contact_method_name IS NOT NULL AND contact_method_icon_library IS NOT NULL AND contact_method_icon_name IS NOT NULL)",
      name: "interactions_contact_method_icon_is_complete"
  end

  def down
    add_column :interactions, :contact_method, :string
    remove_check_constraint :interactions, name: "interactions_contact_method_icon_is_complete"
    remove_check_constraint :interactions, name: "interactions_contact_method_icon_name_length"
    remove_check_constraint :interactions, name: "interactions_contact_method_icon_library_length"
    remove_check_constraint :interactions, name: "interactions_contact_method_name_length"
    remove_column :interactions, :contact_method_icon_name
    remove_column :interactions, :contact_method_icon_library
    remove_column :interactions, :contact_method_name
    add_check_constraint :interactions,
      "contact_method IS NULL OR contact_method IN ('call', 'message', 'video', 'in_person', 'other')",
      name: "interactions_contact_method_is_supported"
  end
end
