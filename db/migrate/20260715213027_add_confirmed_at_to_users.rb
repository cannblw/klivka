class AddConfirmedAtToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :confirmed_at, :datetime

    # Accounts that predate the confirmation feature are grandfathered in
    reversible do |dir|
      dir.up { execute "UPDATE users SET confirmed_at = created_at" }
    end
  end
end
