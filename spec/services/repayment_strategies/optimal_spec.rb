require 'rails_helper'

RSpec.describe RepaymentStrategies::Optimal do
  subject(:strategy) { described_class.new }

  def realtime
    start = Process.clock_gettime(Process::CLOCK_MONOTONIC)
    yield
    Process.clock_gettime(Process::CLOCK_MONOTONIC) - start
  end

  # 精算結果からメンバーごとの収支(受取 - 支払)を再計算し、元のbalancesと一致することを確認するヘルパー。
  # 複数の最適解がありうるケースでは、厳密なfrom/toの組み合わせではなくこの不変条件で検証する。
  def net(repayments, member_id)
    repayments.select { |t| t[:to] == member_id }.sum { |t| t[:amount] } -
      repayments.select { |t| t[:from] == member_id }.sum { |t| t[:amount] }
  end

  describe '#calculate' do
    context '残高が空の場合' do
      it '精算なし' do
        expect(strategy.calculate({})).to eq([])
      end
    end

    context '全員の残高が0の場合' do
      it '精算なし' do
        expect(strategy.calculate({ a: 0, b: 0 })).to eq([])
      end
    end

    context '残高の絶対値が0.5未満の場合(端数として無視される閾値の内側)' do
      it '精算なし' do
        expect(strategy.calculate({ a: 0.4, b: -0.4 })).to eq([])
      end
    end

    context '残高の絶対値がちょうど0.5の場合(端数として無視される閾値の境界)' do
      it '精算対象に含まれ1円として精算される' do
        expect(strategy.calculate({ a: 0.5, b: -0.5 }))
          .to eq([ { from: :b, to: :a, amount: 1 } ])
      end
    end

    context '取引金額がちょうどX.5円になり四捨五入が発生する場合' do
      it '0から遠ざかる方向に丸められる(RubyのFloat#round準拠)' do
        expect(strategy.calculate({ a: 500.5, b: -500.5 }))
          .to eq([ { from: :b, to: :a, amount: 501 } ])
      end
    end

    context '債権者1人・債務者1人の場合' do
      it '1件で精算される' do
        expect(strategy.calculate({ a: 1000, b: -1000 }))
          .to eq([ { from: :b, to: :a, amount: 1000 } ])
      end
    end

    context '債権者1人に対して債務者が複数いる場合' do
      it '取引数が債務者の人数と一致し、全員が債権者に支払う' do
        balances = { a: 3000, b: -1000, c: -1000, d: -1000 }
        result = strategy.calculate(balances)

        expect(result.size).to eq(3)
        expect(result).to all(include(to: :a))
        balances.each_key { |id| expect(net(result, id)).to eq(balances[id]) }
      end
    end

    context '2対2で複数の最適解がありうる場合' do
      # a:+1000, b:+1000, c:-1000, d:-1000
      # (a-c, b-d) と (a-d, b-c) のどちらの組み合わせも取引数2件で最適になりうる
      it '取引数が理論上の最小(2件)になり、各自の収支が保存される' do
        balances = { a: 1000, b: 1000, c: -1000, d: -1000 }
        result = strategy.calculate(balances)

        expect(result.size).to eq(2)
        balances.each_key { |id| expect(net(result, id)).to eq(balances[id]) }
      end
    end

    context '独立した2グループが混在し、貪欲法だと非最適になりうる場合' do
      # {a:+6000,b:-3000,c:-3000} と {d:+4000,e:-4000} は互いに無関係なグループ
      # 貪欲法(残高順マッチング)だとグループを跨いだ組み合わせになり4件になりうるが、
      # 最適解はグループごとに閉じた3件で済む
      it '精算が理論上の最小(3件)で済む' do
        balances = { a: 6000, b: -3000, c: -3000, d: 4000, e: -4000 }
        result = strategy.calculate(balances)

        expect(result.size).to eq(3)
        balances.each_key { |id| expect(net(result, id)).to eq(balances[id]) }
      end
    end

    context '債権者・債務者の人数比が大きく偏っている場合(1人 対 9人)' do
      it '取引数が債務者数(9件)と一致する' do
        balances = { rich: 9000 }
        9.times { |i| balances[:"poor#{i}"] = -1000 }

        result = strategy.calculate(balances)

        expect(result.size).to eq(9)
        balances.each_key { |id| expect(net(result, id)).to eq(balances[id]) }
      end
    end

    context '人数が多い場合(債権者5人・債務者5人)' do
      it '一定時間内に完了し、取引数が理論上の最小(5件)になる' do
        balances = {}
        5.times { |i| balances[:"c#{i}"] = 1000 }
        5.times { |i| balances[:"d#{i}"] = -1000 }

        result = nil
        elapsed = realtime { result = strategy.calculate(balances) }

        expect(elapsed).to be < 5.0
        expect(result.size).to eq(5)
        balances.each_key { |id| expect(net(result, id)).to eq(balances[id]) }
      end
    end

    context '人数が多く金額もバラバラで組み合わせ探索が困難な場合(12人)' do
      it '一定時間内に完了し、各自の収支が保存される' do
        balances = {
          m0: 50, m1: 40, m2: 33, m3: 21, m4: 19,
          m5: -12, m6: -15, m7: -18, m8: -22, m9: -25, m10: -30, m11: -41
        }

        result = nil
        elapsed = realtime { result = strategy.calculate(balances) }

        expect(elapsed).to be < 5.0
        balances.each_key { |id| expect(net(result, id)).to eq(balances[id]) }
      end
    end
  end
end
