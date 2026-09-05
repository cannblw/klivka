class PeopleSorter
  SORTS = {
    "name" => { name: :asc, id: :asc },
    "recently_added" => { created_at: :desc, name: :asc, id: :asc },
    "recently_updated" => { updated_at: :desc, name: :asc, id: :asc },
    "recently_contacted" => nil,
    "least_recently_contacted" => nil
  }.freeze
  DEFAULT_SORT = "name"

  def initialize(scope, sort:)
    @scope = scope
    @sort = sort
  end

  def call
    database_order = SORTS.fetch(sort)
    return scope.order(database_order).to_a if database_order

    latest_contacts = Interaction.where(person_id: scope.select(:id)).group(:person_id).maximum(:occurred_on)
    scope.to_a.sort_by do |person|
      last_contact = latest_contacts[person.id]
      contact_order = if sort == "recently_contacted"
        [ last_contact ? 0 : 1, last_contact ? -last_contact.jd : 0 ]
      else
        [ last_contact ? 1 : 0, last_contact&.jd || 0 ]
      end
      [ *contact_order, PersonNameNormalizer.call(person.name), person.id ]
    end
  end

  private

  attr_reader :scope, :sort
end
