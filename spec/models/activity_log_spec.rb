require 'rails_helper'

RSpec.describe ActivityLog, type: :model do
  describe 'validations' do
    it '定義済みのaction以外は無効' do
      expect(build(:activity_log, action: 'member.update')).to be_invalid
    end

    it 'subjectが無いと無効' do
      expect(build(:activity_log, subject: nil)).to be_invalid
    end
  end

  describe '追記専用' do
    let!(:log) { create(:activity_log) }

    it '更新できない' do
      expect { log.update!(action: 'member.destroy') }.to raise_error(ActiveRecord::ReadOnlyRecord)
    end

    it '削除できない' do
      expect { log.destroy! }.to raise_error(ActiveRecord::ReadOnlyRecord)
    end

    it 'グループの削除には巻き込まれる' do
      expect { log.group.destroy! }.to change(ActivityLog, :count).by(-1)
    end
  end

  describe '.record' do
    let(:group) { create(:group) }
    let(:member) { create(:member, group: group, name: '田中') }

    it 'subjectの種別とIDを保存する' do
      log = ActivityLog.record(group: group, action: 'member.create', subject: member, after: member.audit_snapshot)
      expect(log.reload).to have_attributes(subject_type: 'Member', subject_id: member.id, before: nil, after: { 'name' => '田中' })
    end
  end
end
