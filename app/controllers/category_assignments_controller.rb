class CategoryAssignmentsController < ApplicationController
  def update
    person = Current.user.people.active.friendly.find(params[:person_id])
    category = Current.user.categories.find(assignment_params[:category_id]) if assignment_params[:category_id].present?
    person.update!(category: category)

    if assignment_params[:return_to] == "categories"
      redirect_to categories_path, notice: t(".updated", name: person.name)
    else
      redirect_to person_path(person), notice: t(".updated", name: person.name)
    end
  end

  private

  def assignment_params
    params.expect(category_assignment: [ :category_id, :return_to ])
  end
end
