class AddSlugToFriends < ActiveRecord::Migration[8.1]
  def change
    add_column :friends, :slug, :string, null: false
    add_index :friends, [ :user_id, :slug ], unique: true
  end
end
