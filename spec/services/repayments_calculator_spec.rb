require 'rails_helper'

RSpec.describe RepaymentsCalculator do
  let(:group) { create(:group) }
  let(:tanaka) { create(:member, group: group, name: '田中') }
  let(:suzuki) { create(:member, group: group, name: '鈴木') }
  let(:sato)   { create(:member, group: group, name: '佐藤') }
  let(:ito)    { create(:member, group: group, name: '伊藤') }

  describe '#repayments' do
    subject { described_class.new(group).repayments }

    context '支払いがない場合' do
      it '精算なし' do
        is_expected.to be_empty
      end
    end

    context '立替えた人が対象者に自分だけを含む場合（自己負担のみ）' do
      before do
        create(:payment, group: group, payer: tanaka, amount: 1000, participants: [ tanaka ])
      end

      it '精算なし' do
        is_expected.to be_empty
      end
    end

    context '全員が同じ額を均等に立替えている場合' do
      before do
        create(:payment, group: group, payer: tanaka, amount: 2000, participants: [ tanaka, suzuki ])
        create(:payment, group: group, payer: suzuki, amount: 2000, participants: [ tanaka, suzuki ])
      end

      it '精算なし' do
        is_expected.to be_empty
      end
    end

    context '2人グループで1人が立替えた場合' do
      before do
        create(:payment, group: group, payer: tanaka, amount: 2000, participants: [ tanaka, suzuki ])
      end

      it '精算が1件で鈴木が田中に1000円払う' do
        expect(subject.size).to eq(1)
        is_expected.to include({ from: suzuki.id, to: tanaka.id, amount: 1000 })
      end
    end

    context '1人が全員分立替えた場合' do
      # 佐藤が3600円を3人分立替え（各自1200円負担）
      # → 田中1200円・鈴木1200円 を佐藤に支払う
      before do
        create(:payment, group: group, payer: sato, amount: 3600, participants: [ sato, tanaka, suzuki ])
      end

      it '精算が2件で田中と鈴木がそれぞれ佐藤に1200円払う' do
        expect(subject.size).to eq(2)
        is_expected.to include({ from: tanaka.id, to: sato.id, amount: 1200 })
        is_expected.to include({ from: suzuki.id, to: sato.id, amount: 1200 })
      end
    end

    context '複数の支払いがある場合' do
      # 田中がランチ代3600円を全員分立替え（各自1200円負担）
      # 鈴木がレンタカー代12000円を田中・鈴木の2人分立替え（各自6000円負担）
      # 収支: 田中=+3600-1200-6000=-3600, 鈴木=+12000-1200-6000=+4800, 佐藤=-1200
      # → 田中→鈴木 3600円、佐藤→鈴木 1200円
      before do
        create(:payment, group: group, payer: tanaka, amount: 3600, participants: [ tanaka, suzuki, sato ])
        create(:payment, group: group, payer: suzuki, amount: 12000, participants: [ suzuki, tanaka ])
      end

      it '精算が2件で田中が鈴木に3600円・佐藤が鈴木に1200円払う' do
        expect(subject.size).to eq(2)
        is_expected.to include({ from: tanaka.id, to: suzuki.id, amount: 3600 })
        is_expected.to include({ from: sato.id, to: suzuki.id, amount: 1200 })
      end
    end

    context '4人グループで精算回数が最小になる場合' do
      # 田中: +6000（立替） - 1500（負担） = +4500
      # 鈴木: -1500, 佐藤: -1500, 伊藤: -1500
      # → 理論上3件だが、貪欲法で最小になることを確認
      before do
        create(:payment, group: group, payer: tanaka, amount: 6000,
               participants: [ tanaka, suzuki, sato, ito ])
      end

      it '精算が3件（N-1件）で全員が田中に1500円払う' do
        expect(subject.size).to eq(3)
        is_expected.to include({ from: suzuki.id, to: tanaka.id, amount: 1500 })
        is_expected.to include({ from: sato.id,   to: tanaka.id, amount: 1500 })
        is_expected.to include({ from: ito.id,    to: tanaka.id, amount: 1500 })
      end
    end

    context '割り勘対象者が全員でない場合' do
      # 田中が6000円を田中・鈴木の2人分だけ立替え（佐藤は対象外）
      # → 鈴木が田中に3000円払う、佐藤は支払いなし
      before do
        create(:payment, group: group, payer: tanaka, amount: 6000, participants: [ tanaka, suzuki ])
        sato # グループメンバーとして存在させる
      end

      it '精算が1件で鈴木が田中に3000円払い、佐藤は含まれない' do
        expect(subject.size).to eq(1)
        is_expected.to include({ from: suzuki.id, to: tanaka.id, amount: 3000 })
        expect(subject.map { |t| [ t[:from], t[:to] ] }.flatten).not_to include(sato.id)
      end
    end

    context '割り切れない金額の場合' do
      # 1000円を3人で割ると 333.33...円 → round で 333円に丸める
      before do
        create(:payment, group: group, payer: tanaka, amount: 1000,
               participants: [ tanaka, suzuki, sato ])
      end

      it '精算金額が整数で鈴木と佐藤がそれぞれ333円払う' do
        subject.each do |t|
          expect(t[:amount]).to eq(t[:amount].to_i)
        end
        is_expected.to include({ from: suzuki.id, to: tanaka.id, amount: 333 })
        is_expected.to include({ from: sato.id,   to: tanaka.id, amount: 333 })
      end
    end

    context '同じ人が複数回立替えた場合' do
      # 田中が2回立替え: 合計4000円を鈴木に負担させる
      before do
        create(:payment, group: group, payer: tanaka, amount: 2000, participants: [ tanaka, suzuki ])
        create(:payment, group: group, payer: tanaka, amount: 2000, participants: [ tanaka, suzuki ])
      end

      it '精算が1件にまとまり鈴木が田中に2000円払う' do
        expect(subject.size).to eq(1)
        is_expected.to include({ from: suzuki.id, to: tanaka.id, amount: 2000 })
      end
    end

    context '立替え人が割り勘対象者に含まれない場合' do
      # 田中が1200円を鈴木・佐藤のために立替え（田中自身は対象外）
      # 田中: +1200, 鈴木: -600, 佐藤: -600
      before do
        create(:payment, group: group, payer: tanaka, amount: 1200, participants: [ suzuki, sato ])
      end

      it '精算が2件で鈴木と佐藤がそれぞれ田中に600円払う' do
        expect(subject.size).to eq(2)
        is_expected.to include({ from: suzuki.id, to: tanaka.id, amount: 600 })
        is_expected.to include({ from: sato.id,   to: tanaka.id, amount: 600 })
      end
    end

    context '双方向の立替えで残高が相殺される場合' do
      # 田中が2000円を田中・鈴木で割り勘: 田中+1000, 鈴木-1000
      # 鈴木が3000円を田中・鈴木で割り勘: 鈴木+1500, 田中-1500
      # 収支: 田中=-500, 鈴木=+500 → 田中→鈴木 500円（1件）
      before do
        create(:payment, group: group, payer: tanaka, amount: 2000, participants: [ tanaka, suzuki ])
        create(:payment, group: group, payer: suzuki, amount: 3000, participants: [ tanaka, suzuki ])
      end

      it '精算が1件で田中が鈴木に500円払う' do
        expect(subject.size).to eq(1)
        is_expected.to include({ from: tanaka.id, to: suzuki.id, amount: 500 })
      end
    end

    context '双方向の立替えで完全に相殺される場合' do
      # 田中が2000円を田中・鈴木で割り勘: 田中+1000, 鈴木-1000
      # 鈴木が2000円を田中・鈴木で割り勘: 鈴木+1000, 田中-1000
      # 収支: 田中=0, 鈴木=0
      before do
        create(:payment, group: group, payer: tanaka, amount: 2000, participants: [ tanaka, suzuki ])
        create(:payment, group: group, payer: suzuki, amount: 2000, participants: [ tanaka, suzuki ])
      end

      it '精算なし' do
        is_expected.to be_empty
      end
    end

    context '複数の債権者と複数の債務者が混在する場合' do
      # 田中が5000円を4人全員で割り勘: 田中+3750, 鈴木-1250, 佐藤-1250, 伊藤-1250
      # 鈴木が3000円を田中・鈴木の2人で割り勘: 鈴木+1500, 田中-1500
      # 収支: 田中=+2250, 鈴木=+250, 佐藤=-1250, 伊藤=-1250
      # 貪欲法: 佐藤→田中 1250, 伊藤→田中 1000, 伊藤→鈴木 250
      before do
        create(:payment, group: group, payer: tanaka, amount: 5000,
               participants: [ tanaka, suzuki, sato, ito ])
        create(:payment, group: group, payer: suzuki, amount: 3000,
               participants: [ tanaka, suzuki ])
      end

      it '精算が3件で各自正しい金額を払う' do
        expect(subject.size).to eq(3)
        is_expected.to include({ from: sato.id, to: tanaka.id, amount: 1250 })
        is_expected.to include({ from: ito.id,  to: tanaka.id, amount: 1000 })
        is_expected.to include({ from: ito.id,  to: suzuki.id, amount: 250 })
      end
    end

    context '3人グループで全員が均等に立替えている場合' do
      # 3人がそれぞれ3000円を3人全員のために立替え
      # 全員の収支: +3000 - 3000 = 0
      before do
        create(:payment, group: group, payer: tanaka, amount: 3000, participants: [ tanaka, suzuki, sato ])
        create(:payment, group: group, payer: suzuki, amount: 3000, participants: [ tanaka, suzuki, sato ])
        create(:payment, group: group, payer: sato,   amount: 3000, participants: [ tanaka, suzuki, sato ])
      end

      it { is_expected.to be_empty }
    end
  end

  describe '#balances' do
    subject { described_class.new(group).balances }

    context '支払いがない場合' do
      it { is_expected.to be_empty }
    end

    context '1人が全員分立替えた場合' do
      # 佐藤が3600円を3人分立替え（各自1200円負担）
      # 佐藤: +3600 - 1200 = +2400, 田中: -1200, 鈴木: -1200
      before do
        create(:payment, group: group, payer: sato, amount: 3600, participants: [ sato, tanaka, suzuki ])
      end

      it do
        expect(subject[sato.id]).to eq(2400)
        expect(subject[tanaka.id]).to eq(-1200)
        expect(subject[suzuki.id]).to eq(-1200)
      end
    end

    context '全員が均等に立替えている場合' do
      before do
        create(:payment, group: group, payer: tanaka, amount: 3000, participants: [ tanaka, suzuki, sato ])
        create(:payment, group: group, payer: suzuki, amount: 3000, participants: [ tanaka, suzuki, sato ])
        create(:payment, group: group, payer: sato,   amount: 3000, participants: [ tanaka, suzuki, sato ])
      end

      it do
        expect(subject[tanaka.id]).to eq(0)
        expect(subject[suzuki.id]).to eq(0)
        expect(subject[sato.id]).to eq(0)
      end
    end
  end
end
