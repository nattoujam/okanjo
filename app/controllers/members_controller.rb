class MembersController < ApplicationController
  before_action :set_group

  def create
    @member = @group.members.build(member_params)

    if @member.save
      redirect_to group_show_path(@group.token)
    else
      redirect_to group_show_path(@group.token), alert: @member.errors.full_messages.to_sentence
    end
  end

  def destroy
    @group.members.find(params[:id]).destroy
    redirect_to group_show_path(@group.token)
  end

  private

  def set_group
    @group = Group.find_by!(token: params[:token])
  end

  def member_params
    params.require(:member).permit(:name)
  end
end
