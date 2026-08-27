class LimitFriendNameLength < ActiveRecord::Migration[8.1]
  STRING_MAX_LENGTH = 255

  def change
    add_check_constraint :friends,
      "length(name) <= #{STRING_MAX_LENGTH}",
      name: "friends_name_is_within_maximum_length"
  end
end
