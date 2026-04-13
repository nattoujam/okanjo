require 'rails_helper'

RSpec.describe SettlementsController, type: :request do
  describe 'GET /g/:token/settlements' do
    let(:group) { create(:group) }

    subject { get group_settlements_path(group.token) }

    it '200を返す' do
      subject
      expect(response).to have_http_status(:ok)
    end

    it 'グループ名を表示する' do
      subject
      expect(response.body).to include(group.name)
    end

    context '立替払いがある場合' do
      let!(:tanaka) { create(:member, group: group, name: '田中') }
      let!(:suzuki) { create(:member, group: group, name: '鈴木') }
      let!(:sato)   { create(:member, group: group, name: '佐藤') }

      before do
        # 田中が3600円立替え、全員で割り勘
        payment = create(:payment, group: group, payer: tanaka, description: 'ランチ代', amount: 3600,
                                   participants: [ tanaka, suzuki, sato ])
        payment.save!
      end

      it '精算結果を表示する' do
        subject
        expect(response.body).to include('田中')
        expect(response.body).to include('→')
      end

      it '各自の収支を表示する' do
        subject
        expect(response.body).to include('各自の収支')
        expect(response.body).to include('田中')
        expect(response.body).to include('鈴木')
        expect(response.body).to include('佐藤')
      end
    end

    context '立替払いがない場合' do
      it '精算不要メッセージを表示する' do
        subject
        expect(response.body).to include('精算の必要はありません')
      end
    end

    context '存在しないtokenの場合' do
      it '404を返す' do
        get group_settlements_path('nonexistent')
        expect(response).to have_http_status(:not_found)
      end
    end
  end
end
