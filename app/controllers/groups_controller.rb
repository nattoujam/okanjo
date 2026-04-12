class GroupsController < ApplicationController
  def new
    @group = Group.new
  end

  def create
    @group = Group.new(group_params)

    if @group.save
      redirect_to group_show_path(@group.token)
    else
      render :new, status: :unprocessable_entity
    end
  end

  def show
    @group = Group.includes(:members, payments: [ :payer, :payment_participants ]).find_by!(token: params[:token])
  end

  private

  def group_params
    params.require(:group).permit(:name, :memo, members_attributes: [ :name ])
  end
end
