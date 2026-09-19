require 'rails_helper'

RSpec.describe MemberRemover do
  let(:group) { create(:group) }
  let!(:tanaka) { create(:member, group: group, name: '田中') }
  let!(:suzuki) { create(:member, group: group, name: '鈴木') }
  let!(:sato) { create(:member, group: group, name: '佐藤') }

  subject { described_class.new(tanaka).call }

  context '立替も割り勘参加も無いメンバーのとき' do
    it 'member.destroy だけを記録する' do
      expect { subject }.to change(Member, :count).by(-1).and change(ActivityLog, :count).by(1)
      expect(ActivityLog.last).to have_attributes(action: 'member.destroy', subject_id: tanaka.id, before: { 'name' => '田中' }, after: nil)
    end
  end

  context '立替えた支払いがあるとき' do
    let!(:payment) { create(:payment, group: group, payer: tanaka, participants: [ tanaka, suzuki ], description: 'ランチ代') }

    it '連鎖削除される立替を payment.destroy として記録する' do
      expect { subject }.to change(Payment, :count).by(-1)

      log = ActivityLog.find_by(action: 'payment.destroy')
      expect(log).to have_attributes(subject_id: payment.id, after: nil)
      expect(log.before).to include('description' => 'ランチ代', 'payer' => '田中', 'participants' => [ '田中', '鈴木' ])
    end
  end

  context '他人の立替の割り勘対象になっているとき' do
    let!(:payment) { create(:payment, group: group, payer: suzuki, participants: [ tanaka, suzuki, sato ]) }

    it '対象者から外れたことを payment.update として記録する' do
      expect { subject }.not_to change(Payment, :count)

      log = ActivityLog.find_by(action: 'payment.update')
      expect(log.subject_id).to eq(payment.id)
      expect(log.before['participants']).to eq([ '田中', '鈴木', '佐藤' ])
      expect(log.after['participants']).to eq([ '鈴木', '佐藤' ])
    end
  end

  context '自分が立替えた支払いの割り勘対象でもあるとき' do
    let!(:payment) { create(:payment, group: group, payer: tanaka, participants: [ tanaka, suzuki ]) }

    it 'payment.update は記録しない' do
      subject
      expect(ActivityLog.pluck(:action)).to contain_exactly('member.destroy', 'payment.destroy')
    end
  end
end
