class RenameKindToTypeInEntries < ActiveRecord::Migration[8.1]
  def change
    rename_column :entries, :kind, :type
  end
end
