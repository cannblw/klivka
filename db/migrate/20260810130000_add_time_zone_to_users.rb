class AddTimeZoneToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :time_zone, :string, null: false, default: "UTC"
    change_column_default :users, :time_zone, from: "UTC", to: nil
  end
end
