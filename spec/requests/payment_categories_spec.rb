require 'rails_helper'

RSpec.describe PaymentCategoriesController, type: :request do
  let(:group) { create(:group) }
  let(:member) { create(:member, group: group) }
  let!(:day1) { create(:payment_category, group: group, name: '1日目') }
  let!(:day2) { create(:payment_category, group: group, name: '2日目') }
  let!(:day3) { create(:payment_category, group: group, name: '3日目') }

  def add_payment(category)
    create(:payment, :with_participant, group: group, payer: member, category: category)
  end

  def category_names
    group.payment_categories.reload.map(&:name)
  end

  before { [ day1, day2, day3 ].each { |category| add_payment(category) } }

  describe 'PATCH /g/:token/payment_categories/:id/move_up' do
    subject { patch move_up_group_payment_category_path(group.token, category) }

    context '上にカテゴリがある場合' do
      let(:category) { day2 }

      it 'ひとつ前のカテゴリと入れ替える' do
        expect { subject }.to change { category_names }.to([ '2日目', '1日目', '3日目' ])
      end

      it 'グループ詳細画面にリダイレクトする' do
        subject
        expect(response).to redirect_to(group_show_path(group.token))
      end
    end

    context '先頭のカテゴリの場合' do
      let(:category) { day1 }

      it '並び順を変えない' do
        expect { subject }.not_to change { category_names }
      end
    end

    context '立替払いが1件もないカテゴリの場合' do
      let!(:category) { create(:payment_category, group: group, name: '4日目') }

      it '立替払いのあるカテゴリと同じように入れ替える' do
        expect { subject }.to change { category_names }.to([ '1日目', '2日目', '4日目', '3日目' ])
      end
    end

    context '別のグループのカテゴリを指定した場合' do
      let(:category) { create(:payment_category, group: create(:group)) }

      it '404を返す' do
        subject
        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe 'PATCH /g/:token/payment_categories/:id/move_down' do
    subject { patch move_down_group_payment_category_path(group.token, category) }

    context '下にカテゴリがある場合' do
      let(:category) { day2 }

      it 'ひとつ後のカテゴリと入れ替える' do
        expect { subject }.to change { category_names }.to([ '1日目', '3日目', '2日目' ])
      end

      it 'グループ詳細画面にリダイレクトする' do
        subject
        expect(response).to redirect_to(group_show_path(group.token))
      end
    end

    context '末尾のカテゴリの場合' do
      let(:category) { day3 }

      it '並び順を変えない' do
        expect { subject }.not_to change { category_names }
      end
    end
  end
end
