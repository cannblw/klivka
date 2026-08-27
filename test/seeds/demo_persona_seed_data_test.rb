require "test_helper"

class DemoPersonaSeedDataTest < ActiveSupport::TestCase
  setup do
    @user = User.create!(email_address: "demo-personas@example.com", password: "password")
    DemoPersonaSeedData.call(user: @user)
  end

  test "creates seventeen detailed fictional personas" do
    assert_equal DemoPersonaSeedData::PERSON_COUNT, @user.people.count
    assert_equal 15, @user.people.active.count
    assert_equal 2, @user.people.archived.count
    assert_equal DemoPersonaSeedData::PERSONAS.map { |persona| persona.fetch(:name) }, @user.people.order(:id).pluck(:name)
    assert_operator @user.people.joins(:entries).where(entries: { type: "Entry::Note" }).count, :>=, 15
    assert_equal 17, @user.people.joins(:entries).where(entries: { type: "Entry::Birthday" }).count
    assert_equal 17, @user.people.joins(:entries).where(entries: { type: "Entry::FirstMet" }).count
    assert_equal 17, @user.people.joins(:entries).where(entries: { type: "Entry::GiftList" }).count
    assert_equal 106, @user.people.joins(:interactions).count
    assert_equal 22, @user.people.find_by!(name: "Marcus Chen").interactions.count
    assert_equal 30, @user.people.find_by!(name: "Sofía Álvarez").interactions.count
    assert_equal 26, @user.people.find_by!(name: "Claire Dubois").interactions.count
  end

  test "archives two complete fictional personas" do
    archived_people = @user.people.archived.includes(:entries, :interactions).order(:name).to_a

    assert_equal [ "Daniel Kim", "Ruth Mensah" ], archived_people.map(&:name)
    assert archived_people.all? { |person| person.entries.any? }
    assert archived_people.all? { |person| person.interactions.any? }
    assert archived_people.all? { |person| person.keep_in_touch_setting.present? }
  end

  test "preserves the persona stories and gift ideas as structured entries" do
    anna = @user.people.find_by!(name: "Anna Roberts")

    assert_includes anna.entries.find_by!(type: "Entry::Note").content.fetch("text"), "Mechanical engineer"
    assert_equal Date.new(2020, 9, 14), anna.entries.find_by!(type: "Entry::FirstMet").entry_date
    assert_equal "Wedding anniversary", anna.entries.find_by!(type: "Entry::Date").label
    gift_list = anna.entries.find_by!(type: "Entry::GiftList")
    assert_equal "Anna's baking shelf", gift_list.title
    assert_equal "Red digital kitchen scale", gift_list.items.second.fetch("text")
  end

  test "uses reserved fictional contact details" do
    @user.people.includes(:entries).each do |person|
      email = person.entries.find { |entry| entry.type == "Entry::Email" }
      phone = person.entries.find { |entry| entry.type == "Entry::Phone" }

      assert_match(/@example\.com\z/, email.email)
      assert_match(/\A0/, phone.content.fetch("number"))
    end
  end

  test "includes accented Spanish and Polish persona names" do
    assert @user.people.exists?(name: "Sofía Álvarez")
    assert @user.people.exists?(name: "Tomás Hernández")
    assert @user.people.exists?(name: "Elżbieta Wójcik")
    assert @user.people.exists?(name: "Łukasz Zieliński")
  end

  test "replaces only the demo user's existing records" do
    other_user = User.create!(email_address: "other-demo-personas@example.com", password: "password")
    other_person = other_user.people.create!(name: "Unaffected person")
    @user.people.create!(name: "Visitor addition")

    DemoPersonaSeedData.call(user: @user)

    assert_equal DemoPersonaSeedData::PERSON_COUNT, @user.people.count
    assert_not @user.people.exists?(name: "Visitor addition")
    assert_equal other_person, other_user.people.find_by(name: "Unaffected person")
  end
end
