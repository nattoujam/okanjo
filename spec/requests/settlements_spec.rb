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

  describe 'GET /g/:token/settlements/payments.csv' do
    let(:group) { create(:group) }
    let!(:tanaka) { create(:member, group: group, name: '田中') }
    let!(:suzuki) { create(:member, group: group, name: '鈴木') }
    let!(:category) { create(:payment_category, group: group, name: '食費') }

    subject { get group_settlements_payments_csv_path(group.token) }

    before do
      create(:payment, group: group, payer: tanaka, category: category, description: 'ランチ代',
                        amount: 3600, personal_amount: 600, participants: [ tanaka, suzuki ])
    end

    it '200を返しCSVとしてダウンロードされる' do
      subject
      expect(response).to have_http_status(:ok)
      expect(response.media_type).to eq('text/csv')
      expect(response.headers['Content-Disposition']).to include('attachment')
    end

    it '立替払いの内容をCSVに出力する' do
      subject
      expect(response.body).to include('ランチ代', '田中', '食費', '3600', '600', '3000')
    end

    it 'BOMを付与しない' do
      subject
      expect(response.body.b[0..2]).not_to eq("\xEF\xBB\xBF".b)
    end
  end

  describe 'GET /g/:token/settlements/results.csv' do
    let(:group) { create(:group) }
    let!(:tanaka) { create(:member, group: group, name: '田中') }
    let!(:suzuki) { create(:member, group: group, name: '鈴木') }

    subject { get group_settlements_results_csv_path(group.token, algo: 'optimal') }

    before do
      create(:payment, group: group, payer: tanaka, description: 'ランチ代', amount: 2000,
                        participants: [ tanaka, suzuki ])
    end

    it '200を返しCSVとしてダウンロードされる' do
      subject
      expect(response).to have_http_status(:ok)
      expect(response.media_type).to eq('text/csv')
    end

    it '支払う人・受け取る人・金額のみの単一の表としてCSVに出力する' do
      subject
      expect(response.body).to eq("支払う人,受け取る人,金額\n鈴木,田中,1000\n")
    end
  end
end
