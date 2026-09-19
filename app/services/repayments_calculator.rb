class RepaymentsCalculator
  def initialize(group, strategy: RepaymentStrategies::Optimal.new)
    @group    = group
    @strategy = strategy
  end

  def repayments
    @strategy.calculate(balances)
  end

  def balances
    calculate_balances
  end

  private

  def calculate_balances
    charges = Hash.new(0r)
    credits = Hash.new(0)

    @group.payments.each do |payment|
      participants = payment.payment_participants
      share = Rational(payment.split_amount, participants.count)

      credits[payment.payer_member_id] += payment.split_amount
      participants.each { |pp| charges[pp.member_id] += share }
    end

    balances = Hash.new(0)
    round_charges(charges, credits).each { |member_id, charge| balances[member_id] -= charge }
    credits.each { |member_id, credit| balances[member_id] += credit }
    balances
  end

  # 割り勘で割り切れずに出た端数は、割り勘対象者ではなく立替者が引き受ける。
  # 支払いごとに丸めるのではなく全支払いの負担額を合算してから一度だけ丸めるので、
  # 立替が何件あっても立替者が被る端数は1件分に収まる。
  def round_charges(charges, credits)
    rounded  = charges.transform_values(&:round)
    residual = (charges.values.sum - rounded.values.sum).to_i
    payers   = credits.sort_by { |member_id, credit| [ -credit, member_id ] }.map(&:first)
    return rounded if residual.zero? || payers.empty?

    step = residual.positive? ? 1 : -1
    residual.abs.times do |i|
      member_id = payers[i % payers.size]
      rounded[member_id] = rounded.fetch(member_id, 0) + step
    end

    rounded
  end
end
