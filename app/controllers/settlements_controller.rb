class SettlementsController < ApplicationController
  REPAYMENT_STRATEGIES = {
    "greedy"  => RepaymentStrategies::Greedy,
    "optimal" => RepaymentStrategies::Optimal
  }.freeze

  def show
    @algo  = REPAYMENT_STRATEGIES.key?(params[:algo]) ? params[:algo] : "optimal"

    # group + members + payments を常にロード（キャッシュキー生成に必要）
    @group = Group.includes(:members, :payments).find_by!(token: params[:token])

    payments_ts    = @group.payments.map(&:updated_at).max&.to_i || 0
    repayments_key = "settlements/#{@group.token}/#{payments_ts}/#{@algo}"
    balances_key   = "settlements/#{@group.token}/#{payments_ts}/balances"

    raw_repayments = Rails.cache.read(repayments_key)
    raw_balances   = Rails.cache.read(balances_key)

    if raw_repayments.nil? || raw_balances.nil?
      # キャッシュミス: payment_participants を追加ロード（1クエリ）
      ActiveRecord::Associations::Preloader.new(
        records: @group.payments.to_a, associations: [ :payment_participants ]
      ).call

      calculator     = RepaymentsCalculator.new(@group, strategy: REPAYMENT_STRATEGIES[@algo].new)
      raw_repayments = Rails.cache.fetch(repayments_key) { calculator.repayments }
      raw_balances   = Rails.cache.fetch(balances_key)   { calculator.balances.transform_values(&:round) }
    end

    members_by_id = @group.members.index_by(&:id)
    @repayments   = raw_repayments.map { |r| { from: members_by_id[r[:from]], to: members_by_id[r[:to]], amount: r[:amount] } }
    @balances     = raw_balances.map   { |id, b| { member: members_by_id[id], balance: b } }

    render :show
  end
end
