module RepaymentStrategies
  class Optimal
    EPSILON = 0.5
    # 探索するマスク数が 2^人数 になるため、これを超える人数では Greedy に切り替える。
    # 18人で約0.25秒、1人増えるごとに倍になる。
    MAX_EXACT_MEMBERS = 18

    def calculate(balances)
      people = balances.reject { |_, amount| amount.abs < EPSILON }.to_a
      return [] if people.empty?
      return Greedy.new.calculate(balances) if people.size > MAX_EXACT_MEMBERS

      zero_sum_groups(people).flat_map { |group| settle_group(group) }
    end

    private

    # ゼロ和グループの中は、残高の大きい順に突き合わせれば(人数-1)件で閉じられる。
    def settle_group(group)
      creditors = group.select { |_, amount| amount >= EPSILON }.map { |id, amount| [ id, amount ] }.sort_by { |_, amount| -amount }
      debtors   = group.select { |_, amount| amount <= -EPSILON }.map { |id, amount| [ id, amount ] }.sort_by { |_, amount| amount }

      repayments = []
      ci = 0
      di = 0

      while ci < creditors.size && di < debtors.size
        amount  = [ creditors[ci][1], -debtors[di][1] ].min
        rounded = amount.round

        repayments << { from: debtors[di][0], to: creditors[ci][0], amount: rounded } if rounded > 0

        creditors[ci][1] -= amount
        debtors[di][1]   += amount
        ci += 1 if creditors[ci][1] < EPSILON
        di += 1 if debtors[di][1] > -EPSILON
      end

      repayments
    end

    # 残高の合計が0になるグループに分けられれば、グループ内は(人数-1)件で精算できる。
    # よって最小の送金回数は「人数 - ゼロ和グループの最大個数」になり、
    # 最大個数はマスクを1人ずつ削るDPで求められる。
    def zero_sum_groups(people)
      amounts = people.map(&:last)
      full    = (1 << people.size) - 1

      sums = Array.new(full + 1, 0.0)
      # max_groups[mask] = mask の人だけで作れるゼロ和グループの最大個数
      max_groups = Array.new(full + 1, 0)
      # removed[mask] = max_groups[mask] を達成する際に mask から取り除く1人
      removed = Array.new(full + 1, 0)

      1.upto(full) do |mask|
        lowest = mask & -mask
        sums[mask] = sums[mask ^ lowest] + amounts[lowest.bit_length - 1]

        best_groups = -1
        rest = mask
        while rest != 0
          bit   = rest & -rest
          rest ^= bit
          groups = max_groups[mask ^ bit]
          next if groups <= best_groups

          best_groups   = groups
          removed[mask] = bit.bit_length - 1
        end

        max_groups[mask] = best_groups + (sums[mask].abs < EPSILON ? 1 : 0)
      end

      build_groups(people, sums, removed, full)
    end

    # 1人ずつ取り除く過程で残りがゼロ和になった時点が、グループの切れ目になる。
    def build_groups(people, sums, removed, full)
      groups  = []
      current = []
      mask    = full

      while mask != 0
        index = removed[mask]
        current << people[index]
        mask ^= (1 << index)

        if sums[mask].abs < EPSILON
          groups << current
          current = []
        end
      end

      groups
    end
  end
end
