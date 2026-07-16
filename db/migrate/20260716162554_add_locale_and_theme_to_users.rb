class AddLocaleAndThemeToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :locale, :string
    add_column :users, :theme, :string
  end
end
