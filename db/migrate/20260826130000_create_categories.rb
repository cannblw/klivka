class CreateCategories < ActiveRecord::Migration[8.1]
  def change
    create_table :categories do |t|
      t.references :user, null: false, foreign_key: { on_delete: :cascade }
      t.string :name, null: false
      t.string :normalized_name, null: false

      t.timestamps
    end

    add_index :categories, [ :user_id, :normalized_name ], unique: true
    add_check_constraint :categories,
      "length(name) <= #{FriendCrm::STRING_MAX_LENGTH}",
      name: "categories_name_is_within_maximum_length"

    add_reference :friends, :category, null: true, foreign_key: { on_delete: :nullify }
    add_check_constraint :friends,
      "length(name) <= #{FriendCrm::STRING_MAX_LENGTH}",
      name: "friends_name_is_within_maximum_length"
  end
end
