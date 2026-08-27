require "test_helper"

# == Schema Information
#
# Table name: categories
#
#  id              :integer          not null, primary key
#  name            :string           not null
#  normalized_name :string           not null
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  user_id         :integer          not null
#
# Indexes
#
#  index_categories_on_user_id                      (user_id)
#  index_categories_on_user_id_and_normalized_name  (user_id,normalized_name) UNIQUE
#
# Foreign Keys
#
#  user_id  (user_id => users.id) ON DELETE => cascade
#
class CategoryTest < ActiveSupport::TestCase
  test "category belongs to a user" do
    assert_equal users(:one), categories(:family).user
  end

  test "category name is required" do
    category = users(:one).categories.new(name: "  ")

    assert_not category.valid?
    assert category.errors.added?(:name, :blank)
  end

  test "category name has a portable length limit" do
    category = users(:one).categories.new(name: "a" * (Klivka::STRING_MAX_LENGTH + 1))

    assert_not category.valid?
    assert category.errors.added?(:name, :too_long, count: Klivka::STRING_MAX_LENGTH)
  end

  test "category normalizes Unicode and whitespace while preserving capitalization" do
    category = users(:one).categories.create!(name: "  Close\u00A0\u00A0Friends  ")

    assert_equal "Close Friends", category.name
    assert_equal "close friends", category.normalized_name
  end

  test "category names are unique per user after normalization" do
    users(:one).categories.create!(name: "Close Friends")
    duplicate = users(:one).categories.new(name: "  CLOSE   FRIENDS ")

    assert_not duplicate.valid?
    assert duplicate.errors.added?(:name, :taken)
  end

  test "different users can use the same category name" do
    assert_difference "Category.count", 2 do
      users(:one).categories.create!(name: "Community")
      users(:two).categories.create!(name: "community")
    end
  end

  test "database enforces normalized category name uniqueness per user" do
    duplicate = users(:one).categories.new(name: "Family")
    duplicate.valid?

    assert_raises ActiveRecord::RecordNotUnique do
      duplicate.save!(validate: false)
    end
  end

  test "deleting a category leaves its people uncategorized" do
    person = users(:one).people.create!(name: "Katherine Johnson", category: categories(:family))

    categories(:family).destroy!

    assert_nil person.reload.category
  end

  test "deleting a user deletes the user's categories" do
    user = User.create!(email_address: "category-owner@example.com", password: "a-safe-password")
    user.categories.create!(name: "Neighbors")

    assert_difference "Category.count", -1 do
      user.destroy!
    end
  end
end
