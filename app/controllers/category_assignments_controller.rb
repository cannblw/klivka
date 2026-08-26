class CategoryAssignmentsController < ApplicationController
  def update
    friend = Current.user.friends.friendly.find(params[:friend_id])
    category = Current.user.categories.find(assignment_params[:category_id]) if assignment_params[:category_id].present?
    friend.update!(category: category)

    if assignment_params[:return_to] == "categories"
      redirect_to categories_path, notice: t(".updated", name: friend.name)
    else
      redirect_to friend_path(friend), notice: t(".updated", name: friend.name)
    end
  end

  private

  def assignment_params
    params.expect(category_assignment: [ :category_id, :return_to ])
  end
end
