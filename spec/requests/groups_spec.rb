require 'rails_helper'

RSpec.describe GroupsController, type: :request do
  describe 'GET /groups/new' do
    it '200を返す' do
      get new_group_path
      expect(response).to have_http_status(:ok)
    end
  end

  describe 'POST /groups' do
    subject { post groups_path, params: params }

    context '有効なパラメータの場合' do
      let(:params) { { group: { name: 'GW京都旅行' } } }

      it 'グループを作成する' do
        expect { subject }.to change(Group, :count).by(1)
      end

      it 'グループ詳細画面にリダイレクトする' do
        subject
        expect(response).to redirect_to(group_show_path(Group.last.token))
      end
    end

    context 'メンバーを含む場合' do
      let(:params) do
        {
          group: {
            name: 'GW京都旅行',
            members_attributes: [
              { name: '田中' },
              { name: '鈴木' }
            ]
          }
        }
      end

      it 'グループとメンバーを作成する' do
        expect { subject }.to change(Group, :count).by(1).and change(Member, :count).by(2)
      end
    end

    context '無効なパラメータの場合' do
      let(:params) { { group: { name: '' } } }

      it 'グループを作成しない' do
        expect { subject }.not_to change(Group, :count)
      end

      it 'newをレンダリングして422を返す' do
        subject
        expect(response).to have_http_status(:unprocessable_content)
      end
    end
  end

  describe 'GET /g/:token' do
    let(:group) { create(:group) }

    subject { get group_show_path(group.token) }

    it '200を返す' do
      subject
      expect(response).to have_http_status(:ok)
    end

    it 'グループ名を表示する' do
      subject
      expect(response.body).to include(group.name)
    end

    context 'メンバーがいる場合' do
      let!(:member) { create(:member, group: group, name: '田中') }

      it 'メンバー名を表示する' do
        subject
        expect(response.body).to include('田中')
      end
    end

    context '立替払いがある場合' do
      let!(:member) { create(:member, group: group) }
      let!(:payment) { create(:payment, group: group, payer: member, description: 'ランチ代', amount: 3600) }

      it '立替払いの内容と金額を表示する' do
        subject
        expect(response.body).to include('ランチ代')
        expect(response.body).to include('3,600')
      end
    end

    context '存在しないtokenの場合' do
      it '404を返す' do
        get group_show_path('nonexistent')
        expect(response).to have_http_status(:not_found)
      end
    end
  end
end
