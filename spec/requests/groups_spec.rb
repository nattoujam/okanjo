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
      let!(:payment) { create(:payment, :with_participant, group: group, payer: member, description: 'ランチ代', amount: 3600) }

      it '立替払いの内容と金額を表示する' do
        subject
        expect(response.body).to include('ランチ代')
        expect(response.body).to include('3,600')
      end
    end

    context 'カテゴリがある場合' do
      let!(:member) { create(:member, group: group) }
      let!(:day1) { create(:payment_category, group: group, name: '1日目') }
      let!(:lunch) { create(:payment, :with_participant, group: group, payer: member, category: day1, description: 'ランチ代', amount: 3600) }
      let!(:misc) { create(:payment, :with_participant, group: group, payer: member, description: '雑費', amount: 1200) }

      it 'カテゴリ名と未分類の見出しを表示する' do
        subject
        expect(response.body).to include('1日目')
        expect(response.body).to include('未分類')
      end

      it 'カテゴリごとの小計を表示する' do
        subject
        expect(response.body).to include('3,600')
        expect(response.body).to include('1,200')
      end
    end

    context 'カテゴリと未分類が混在する場合' do
      let!(:member) { create(:member, group: group) }
      let!(:day1) { create(:payment_category, group: group, name: '1日目') }
      let!(:day2) { create(:payment_category, group: group, name: '2日目') }
      let!(:empty) { create(:payment_category, group: group, name: '3日目') }

      def create_payment(category:, description:, created_at: Time.current)
        create(:payment, :with_participant, group: group, payer: member,
               category: category, description: description, created_at: created_at)
      end

      let!(:lunch)  { create_payment(category: day1, description: '昼食', created_at: 3.hours.ago) }
      let!(:train)  { create_payment(category: day1, description: '交通費', created_at: 1.hour.ago) }
      let!(:dinner) { create_payment(category: day2, description: '夕食') }
      let!(:misc)   { create_payment(category: nil, description: '雑費') }

      def headings
        response.body.scan(%r{<h3[^>]*>(.*?)</h3>}m).flatten.map(&:strip)
      end

      it 'カテゴリをsequence順に並べ、未分類を最後に表示する' do
        subject
        expect(headings).to eq([ '1日目', '2日目', '未分類' ])
      end

      it '立替払いが1件もないカテゴリの見出しを表示しない' do
        subject
        expect(headings).not_to include('3日目')
      end

      it 'カテゴリ内は作成日時の新しい順に表示する' do
        subject
        expect(response.body.index('交通費')).to be < response.body.index('昼食')
      end
    end

    context 'カテゴリが1件もない場合' do
      let!(:member) { create(:member, group: group) }
      let!(:payment) { create(:payment, :with_participant, group: group, payer: member, description: 'ランチ代') }

      it '未分類の見出しを表示しない' do
        subject
        expect(response.body).not_to include('未分類')
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
