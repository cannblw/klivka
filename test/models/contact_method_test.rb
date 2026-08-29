require "test_helper"

# == Schema Information
#
# Table name: contact_methods
#
#  id              :integer          not null, primary key
#  enabled         :boolean          default(FALSE), not null
#  icon_library    :string
#  icon_name       :string
#  name            :string           not null
#  normalized_name :string           not null
#  position        :integer
#  provided        :boolean          default(FALSE), not null
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  user_id         :integer          not null
#
# Indexes
#
#  index_contact_methods_on_user_id                           (user_id)
#  index_contact_methods_on_user_id_and_enabled_and_position  (user_id,enabled,position)
#  index_contact_methods_on_user_id_and_normalized_name       (user_id,normalized_name) UNIQUE
#
# Foreign Keys
#
#  user_id  (user_id => users.id) ON DELETE => cascade
#
class ContactMethodTest < ActiveSupport::TestCase
  test "contact method belongs to a user" do
    assert_equal users(:one), contact_methods(:one_call).user
  end

  test "contact method name is required" do
    contact_method = users(:one).contact_methods.new(name: "  ", enabled: true, position: 7)

    assert_not contact_method.valid?
    assert contact_method.errors.added?(:name, :blank)
  end

  test "contact method name has a portable length limit" do
    contact_method = users(:one).contact_methods.new(
      name: "a" * (Klivka::STRING_MAX_LENGTH + 1), enabled: true, position: 7
    )

    assert_not contact_method.valid?
    assert contact_method.errors.added?(:name, :too_long, count: Klivka::STRING_MAX_LENGTH)
  end

  test "contact method normalizes Unicode and whitespace while preserving capitalization" do
    contact_method = users(:one).contact_methods.create!(
      name: "  Wire\u00A0 and   two glasses  ", enabled: true, position: 7
    )

    assert_equal "Wire and two glasses", contact_method.name
    assert_equal "wire and two glasses", contact_method.normalized_name
  end

  test "contact method names are unique per user across enabled and disabled methods" do
    duplicate = users(:one).contact_methods.new(name: "  WHATSAPP ", enabled: true, position: 7)

    assert_not duplicate.valid?
    assert duplicate.errors.added?(:name, :taken)
  end

  test "different users can use the same contact method name" do
    users(:one).contact_methods.create!(name: "Radio", enabled: true, position: 7)

    assert_predicate users(:two).contact_methods.new(name: "Radio", enabled: true, position: 7), :valid?
  end

  test "contact method icon is optional" do
    assert_predicate users(:one).contact_methods.new(name: "Radio", enabled: true, position: 7), :valid?
  end

  test "contact method icon library and name must identify a supported pair" do
    contact_method = users(:one).contact_methods.new(
      name: "Radio", icon_library: "simple_icons", icon_name: "unknown", enabled: true, position: 7
    )

    assert_not contact_method.valid?
    assert contact_method.errors.added?(:icon_name, :inclusion)
  end

  test "enabled methods require a position" do
    contact_method = users(:one).contact_methods.new(name: "Radio", enabled: true)

    assert_not contact_method.valid?
    assert contact_method.errors.added?(:position, :not_a_number, value: nil)
  end

  test "disabled methods do not retain a position" do
    contact_method = contact_methods(:one_wechat)
    contact_method.position = 7

    assert_not contact_method.valid?
    assert contact_method.errors.added?(:position, :present)
  end

  test "database enforces normalized name uniqueness per user" do
    existing = users(:one).contact_methods.create!(name: "Radio", enabled: true, position: 7)
    duplicate = existing.dup
    duplicate.name = "Different display value"

    assert_raises ActiveRecord::RecordNotUnique do
      duplicate.save!(validate: false)
    end
  end

  test "database requires enabled methods to have a position" do
    contact_method = contact_methods(:one_call)

    assert_raises ActiveRecord::StatementInvalid do
      contact_method.update_columns(position: nil)
    end
  end

  test "database requires the icon library and name together" do
    contact_method = contact_methods(:one_call)

    assert_raises ActiveRecord::StatementInvalid do
      contact_method.update_columns(icon_name: nil)
    end
  end

  test "new users receive enabled defaults and disabled provided methods" do
    user = User.create!(email_address: "method-owner@example.com", password: "a-safe-password")

    assert_equal 7, user.contact_methods.enabled.count
    assert_equal ContactMethod::PROVIDED_METHODS.size - 7, user.contact_methods.disabled.count
    assert user.contact_methods.all?(&:provided?)
    assert_equal 0..6, user.contact_methods.enabled.ordered.pluck(:position).minmax.then { |min, max| min..max }
  end

  test "deleting a user deletes their contact methods" do
    user = User.create!(email_address: "method-owner@example.com", password: "a-safe-password")

    assert_difference "ContactMethod.count", -ContactMethod::PROVIDED_METHODS.size do
      user.destroy!
    end
  end
end
