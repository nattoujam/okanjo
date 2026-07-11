module RepaymentStrategies
  class Greedy
    def calculate(balances)
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
end
