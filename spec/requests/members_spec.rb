require 'rails_helper'

RSpec.describe MembersController, type: :request do
  let(:group) { create(:group) }

  describe 'POST /g/:token/members' do
    subject { post group_members_path(group.token), params: params }

    context '有効なパラメータの場合' do
      let(:params) { { member: { name: '田中' } } }

      it 'メンバーを作成する' do
        expect { subject }.to change(Member, :count).by(1)
      end

      it 'グループ詳細画面にリダイレクトする' do
        subject
        expect(response).to redirect_to(group_show_path(group.token))
      end
    end

    context '無効なパラメータの場合' do
      let(:params) { { member: { name: '' } } }

      it 'メンバーを作成しない' do
        expect { subject }.not_to change(Member, :count)
      end

      it 'グループ詳細画面にリダイレクトする' do
        subject
        expect(response).to redirect_to(group_show_path(group.token))
      end
    end
  end

  describe 'DELETE /g/:token/members/:id' do
    let!(:member) { create(:member, group: group) }

    subject { delete group_member_path(group.token, member) }

    it 'メンバーを削除する' do
      expect { subject }.to change(Member, :count).by(-1)
    end

    it 'グループ詳細画面にリダイレクトする' do
      subject
      expect(response).to redirect_to(group_show_path(group.token))
    end
  end
end
