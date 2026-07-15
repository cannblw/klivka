class AddUserToFriends < ActiveRecord::Migration[8.1]
  def change
    # Pre-release throwaway data: wiping is simpler than backfilling an owner
    reversible do |dir|
      dir.up do
        execute "DELETE FROM entries"
        execute "DELETE FROM friends"
      end
    end

    add_reference :friends, :user, null: false, foreign_key: true
  end
end
