class RepaymentsCalculator
  def initialize(group)
    @group = group
  end

  def repayments
    calculate_repayments(balances)
  end

  def balances
    calculate_balances
  end

  private

  def calculate_balances
    balances = Hash.new(0)

    @group.payments.includes(:payment_participants).each do |payment|
      participants = payment.payment_participants
      share = payment.amount.to_f / participants.count

      balances[payment.payer_member_id] += payment.amount

      participants.each do |pp|
        balances[pp.member_id] -= share
      end
    end

    balances
  end

  def calculate_repayments(balances)
    # 最小取引数アルゴリズム（貪欲法）
    repayments = []

    creditors = balances.select { |_, v| v > 0.5 }.sort_by { |_, v| -v }.to_a
    debtors   = balances.select { |_, v| v < -0.5 }.sort_by { |_, v| v }.to_a

    ci = 0
    di = 0

    while ci < creditors.size && di < debtors.size
      cid, credit = creditors[ci]
      did, debt   = debtors[di]

      amount = [ credit, -debt ].min.round

      repayments << { from: did, to: cid, amount: amount } if amount > 0

      creditors[ci][1] -= amount
      debtors[di][1]   += amount

      ci += 1 if creditors[ci][1] < 0.5
      di += 1 if debtors[di][1] > -0.5
    end

    repayments
  end
end
