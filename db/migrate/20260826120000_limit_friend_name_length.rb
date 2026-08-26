class LimitFriendNameLength < ActiveRecord::Migration[8.1]
  def change
    add_check_constraint :friends,
      "length(name) <= #{FriendCrm::STRING_MAX_LENGTH}",
      name: "friends_name_is_within_maximum_length"
  end
end
