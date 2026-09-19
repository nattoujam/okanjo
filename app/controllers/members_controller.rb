class MembersController < ApplicationController
  before_action :set_group

  def create
    @member = @group.members.build(member_params)

    ActiveRecord::Base.transaction do
      @member.save!
      ActivityLog.record(group: @group, action: "member.create", subject: @member, after: @member.audit_snapshot)
    end
    redirect_to group_show_path(@group.token)
  rescue ActiveRecord::RecordInvalid
    redirect_to group_show_path(@group.token), alert: @member.errors.full_messages.to_sentence
  end

  def destroy
    MemberRemover.new(@group.members.find(params[:id])).call
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
