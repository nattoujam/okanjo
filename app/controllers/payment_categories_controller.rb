class PaymentCategoriesController < ApplicationController
  before_action :set_group
  before_action :set_category

  def move_up
    move_by(-1)
  end

  def move_down
    move_by(1)
  end

  private

  def move_by(offset)
    target = neighbor(offset)
    @category.swap_sequence_with!(target) if target

    redirect_to group_show_path(@group.token)
  end

  def neighbor(offset)
    siblings = @group.payment_categories.to_a
    target_index = siblings.index(@category) + offset

    siblings[target_index] unless target_index.negative?
  end

  def set_group
    @group = Group.find_by!(token: params[:token])
  end

  def set_category
    @category = @group.payment_categories.find(params[:id])
  end
end
