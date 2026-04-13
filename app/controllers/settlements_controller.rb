class SettlementsController < ApplicationController
  def show
    @group = Group.includes(:members, payments: :payment_participants).find_by!(token: params[:token])
    members_by_id = @group.members.index_by(&:id)
    calculator = RepaymentsCalculator.new(@group)

    @repayments = calculator.repayments.map do |r|
      { from: members_by_id[r[:from]], to: members_by_id[r[:to]], amount: r[:amount] }
    end

    @balances = calculator.balances.map do |id, balance|
      { member: members_by_id[id], balance: balance.round }
    end

    render :show
  end
end
