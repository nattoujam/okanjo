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

      it 'root_pathにリダイレクトする' do
        subject
        expect(response).to redirect_to(root_path)
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
end
