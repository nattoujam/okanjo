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
    let(:valid_attributes) do
      { payer_member_id: member.id, description: 'ランチ代', amount: 3600, member_ids: [ member.id ] }
    end

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

    context '自分用の金額（personal_amount）を指定した場合' do
      let(:params) do
        {
          payment: {
            payer_member_id: member.id,
            description: 'スーパー',
            amount: 3600,
            personal_amount: 600,
            member_ids: [ member.id ]
          }
        }
      end

      it '立替払いを作成する' do
        expect { subject }.to change(Payment, :count).by(1)
        expect(Payment.last.personal_amount).to eq(600)
      end
    end

    context '自分用の金額が支払い金額以上の場合' do
      let(:params) do
        {
          payment: {
            payer_member_id: member.id,
            description: 'スーパー',
            amount: 3600,
            personal_amount: 3600,
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

    context '既存のカテゴリを選択した場合' do
      let!(:category) { create(:payment_category, group: group) }
      let(:params) { { payment: valid_attributes.merge(payment_category_id: category.id) } }

      it 'カテゴリを新規作成せずに紐づける' do
        expect { subject }.not_to change(PaymentCategory, :count)
        expect(Payment.last.category).to eq(category)
      end
    end

    context '他の割り勘グループのカテゴリを指定した場合' do
      let(:other_category) { create(:payment_category, group: create(:group)) }
      let(:params) { { payment: valid_attributes.merge(payment_category_id: other_category.id) } }

      it '未分類として作成する' do
        subject
        expect(Payment.last.category).to be_nil
      end
    end

    context '新しいカテゴリ名を入力した場合' do
      let(:params) do
        { payment: valid_attributes.merge(payment_category_id: PaymentsController::NEW_CATEGORY, new_category_name: ' 1日目 ') }
      end

      it 'カテゴリを作成して紐づける' do
        expect { subject }.to change(PaymentCategory, :count).by(1)
        expect(Payment.last.category.name).to eq('1日目')
      end
    end

    context '新しいカテゴリを選んだが名前が空の場合' do
      let(:params) do
        { payment: valid_attributes.merge(payment_category_id: PaymentsController::NEW_CATEGORY, new_category_name: '  ') }
      end

      it '未分類として作成する' do
        expect { subject }.not_to change(PaymentCategory, :count)
        expect(Payment.last.category).to be_nil
      end
    end

    context '新しいカテゴリ名が既存のカテゴリと同名の場合' do
      let!(:category) { create(:payment_category, group: group, name: '1日目') }
      let(:params) do
        { payment: valid_attributes.merge(payment_category_id: PaymentsController::NEW_CATEGORY, new_category_name: '1日目') }
      end

      it '既存のカテゴリを再利用する' do
        expect { subject }.not_to change(PaymentCategory, :count)
        expect(Payment.last.category).to eq(category)
      end
    end

    context '新しいカテゴリ名を入力したが立替払いが無効な場合' do
      let(:params) do
        {
          payment: valid_attributes.merge(
            description: '',
            payment_category_id: PaymentsController::NEW_CATEGORY,
            new_category_name: '1日目'
          )
        }
      end

      it '立替払いもカテゴリも作成しない' do
        expect { subject }.not_to change(PaymentCategory, :count)
        expect(Payment.count).to eq(0)
      end
    end
  end

  describe 'GET /g/:token/payments/:id/edit' do
    let(:payment) { create(:payment, :with_participant, group: group, payer: member) }

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
    let!(:payment) { create(:payment, :with_participant, group: group, payer: member, description: 'ランチ代', amount: 3600) }

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

    context '自分用の金額（personal_amount）を指定した場合' do
      let(:params) do
        {
          payment: {
            payer_member_id: member.id,
            description: '夕食代',
            amount: 5000,
            personal_amount: 1000,
            member_ids: [ member.id ]
          }
        }
      end

      it '立替払いを更新する' do
        subject
        expect(payment.reload.personal_amount).to eq(1000)
      end
    end

    context 'カテゴリを付け替える場合' do
      let(:valid_attributes) do
        { payer_member_id: member.id, description: 'ランチ代', amount: 3600, member_ids: [ member.id ] }
      end
      let!(:day1) { create(:payment_category, group: group) }
      let!(:day2) { create(:payment_category, group: group) }

      before { payment.update!(category: day1) }

      context '別の既存カテゴリを選んだ場合' do
        let(:params) { { payment: valid_attributes.merge(payment_category_id: day2.id) } }

        it 'カテゴリを差し替える' do
          subject
          expect(payment.reload.category).to eq(day2)
        end
      end

      context '未分類を選んだ場合' do
        let(:params) { { payment: valid_attributes.merge(payment_category_id: '') } }

        it 'カテゴリを外す' do
          subject
          expect(payment.reload.category).to be_nil
        end
      end

      context '新しいカテゴリ名を入力した場合' do
        let(:params) do
          { payment: valid_attributes.merge(payment_category_id: PaymentsController::NEW_CATEGORY, new_category_name: '3日目') }
        end

        it 'カテゴリを作成して紐づける' do
          expect { subject }.to change(PaymentCategory, :count).by(1)
          expect(payment.reload.category.name).to eq('3日目')
        end
      end
    end
  end

  describe 'DELETE /g/:token/payments/:id' do
    let!(:payment) { create(:payment, :with_participant, group: group, payer: member) }

    subject { delete group_payment_path(group.token, payment) }

    it '立替払いを削除する' do
      expect { subject }.to change(Payment, :count).by(-1)
    end

    it 'グループ詳細画面にリダイレクトする' do
      subject
      expect(response).to redirect_to(group_show_path(group.token))
    end
  end
end
