module RepaymentStrategies
  class Optimal
    def calculate(balances)
      people = balances.reject { |_, v| v.abs < 0.5 }.to_a
      find_min(people) || []
    end

    private

    def find_min(people, budget = Float::INFINITY)
      active = people.reject { |_, v| v.abs < 0.5 }
      return [] if active.empty?

      lower = [ active.count { |_, v| v > 0 }, active.count { |_, v| v < 0 } ].max
      return nil if lower > budget

      first_id, first_amt = active[0]
      best = nil

      active[1..].each do |other_id, other_amt|
        next if first_amt * other_amt >= 0

        exact_amount = [ first_amt.abs, other_amt.abs ].min
        tx_amount    = exact_amount.round

        tx = if first_amt > 0
          { from: other_id, to: first_id, amount: tx_amount }
        else
          { from: first_id, to: other_id, amount: tx_amount }
        end

        updated = active.map do |id, amt|
          case id
          when first_id  then [ id, first_amt > 0 ? first_amt - exact_amount : first_amt + exact_amount ]
          when other_id  then [ id, other_amt > 0 ? other_amt - exact_amount : other_amt + exact_amount ]
          else                [ id, amt ]
          end
        end

        sub_budget = [ budget - 1, best ? best.length - 1 : Float::INFINITY ].min
        sub = find_min(updated, sub_budget)
        next unless sub

        candidate = [ tx ] + sub
        best = candidate if best.nil? || candidate.length < best.length
      end

      best
    end
  end
end
