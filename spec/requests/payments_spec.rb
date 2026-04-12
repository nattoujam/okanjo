require 'rails_helper'

RSpec.describe PaymentsController, type: :request do
  let(:group) { create(:group) }
  let!(:member) { create(:member, group: group, name: '田中') }

  describe 'GET /g/:token/payments/new' do
    subject { get new_group_payment_path(group.token) }

    it '200を返す' do
      subject
      expect(response).to have_http_status(:ok)
    end

    it 'メンバー名を表示する' do
      subject
      expect(response.body).to include('田中')
    end
  end

  describe 'POST /g/:token/payments' do
    subject { post group_payments_path(group.token), params: params }

    context '有効なパラメータの場合' do
      let(:params) do
        {
          payment: {
            payer_member_id: member.id,
            description: 'ランチ代',
            amount: 3600,
            member_ids: [ member.id ]
          }
        }
      end

      it '立替払いを作成する' do
        expect { subject }.to change(Payment, :count).by(1)
      end

      it 'グループ詳細画面にリダイレクトする' do
        subject
        expect(response).to redirect_to(group_show_path(group.token))
      end
    end

    context '割り勘対象者が未選択の場合' do
      let(:params) do
        {
          payment: {
            payer_member_id: member.id,
            description: 'ランチ代',
            amount: 3600,
            member_ids: []
          }
        }
      end

      it '立替払いを作成しない' do
        expect { subject }.not_to change(Payment, :count)
      end

      it 'newをレンダリングして422を返す' do
        subject
        expect(response).to have_http_status(:unprocessable_content)
      end
    end

    context '無効なパラメータの場合' do
      let(:params) do
        {
          payment: {
            payer_member_id: member.id,
            description: '',
            amount: 0,
            member_ids: [ member.id ]
          }
        }
      end

      it '立替払いを作成しない' do
        expect { subject }.not_to change(Payment, :count)
      end

      it 'newをレンダリングして422を返す' do
        subject
        expect(response).to have_http_status(:unprocessable_content)
      end
    end
  end

  describe 'GET /g/:token/payments/:id/edit' do
    let(:payment) { create(:payment, group: group, payer: member) }

    subject { get edit_group_payment_path(group.token, payment) }

    it '200を返す' do
      subject
      expect(response).to have_http_status(:ok)
    end

    it '既存の内容を表示する' do
      subject
      expect(response.body).to include(payment.description)
    end
  end

  describe 'PATCH /g/:token/payments/:id' do
    let!(:payment) { create(:payment, group: group, payer: member, description: 'ランチ代', amount: 3600) }

    subject { patch group_payment_path(group.token, payment), params: params }

    context '有効なパラメータの場合' do
      let(:params) do
        {
          payment: {
            payer_member_id: member.id,
            description: '夕食代',
            amount: 5000,
            member_ids: [ member.id ]
          }
        }
      end

      it '立替払いを更新する' do
        subject
        expect(payment.reload.description).to eq('夕食代')
        expect(payment.reload.amount).to eq(5000)
      end

      it 'グループ詳細画面にリダイレクトする' do
        subject
        expect(response).to redirect_to(group_show_path(group.token))
      end
    end

    context '割り勘対象者が未選択の場合' do
      let(:params) do
        {
          payment: {
            payer_member_id: member.id,
            description: '夕食代',
            amount: 5000,
            member_ids: []
          }
        }
      end

      it '立替払いを更新しない' do
        subject
        expect(payment.reload.description).to eq('ランチ代')
      end

      it 'editをレンダリングして422を返す' do
        subject
        expect(response).to have_http_status(:unprocessable_content)
      end
    end

    context '無効なパラメータの場合' do
      let(:params) do
        {
          payment: {
            payer_member_id: member.id,
            description: '',
            amount: 0,
            member_ids: [ member.id ]
          }
        }
      end

      it '立替払いを更新しない' do
        subject
        expect(payment.reload.description).to eq('ランチ代')
      end

      it 'editをレンダリングして422を返す' do
        subject
        expect(response).to have_http_status(:unprocessable_content)
      end
    end
  end
end
