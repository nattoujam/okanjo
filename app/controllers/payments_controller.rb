class PaymentsController < ApplicationController
  before_action :set_group

  def new
    @payment = Payment.new
  end

  def create
    @payment = @group.payments.build(payment_params)

    if @payment.save
      redirect_to group_show_path(@group.token)
    else
      render :new, status: :unprocessable_content
    end
  end

  private

  def set_group
    @group = Group.includes(:members).find_by!(token: params[:token])
  end

  def payment_params
    params.require(:payment).permit(:payer_member_id, :description, :amount, member_ids: [])
      .then { |p| build_payment_params(p) }
  end

  def build_payment_params(p)
    member_ids = p.delete(:member_ids) || []
    p.merge(
      payment_participants_attributes: member_ids.map { |id| { member_id: id } }
    )
  end
end
