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
    balances = Hash.new(0)

    @group.payments.each do |payment|
      participants = payment.payment_participants
      share = payment.amount.to_f / participants.count

      balances[payment.payer_member_id] += payment.amount

      participants.each do |pp|
        balances[pp.member_id] -= share
      end
    end

    balances
  end
end
