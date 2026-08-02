require 'rails_helper'

RSpec.describe '立替払いの削除', type: :system do
  let(:group) { create(:group, name: 'テストグループ') }
  let!(:member) { create(:member, group: group, name: 'メンバーA') }
  let!(:payment) do
    create(:payment, group: group, payer: member, description: 'テスト支払い', participants: [ member ])
  end

  # 削除確認は Turbo の data-turbo-confirm に任せているので、実ブラウザでしか検証できない
  it '確認ダイアログを承認すると削除される' do
    visit group_show_path(group.token)
    expect(page).to have_content('テスト支払い')

    accept_confirm '「テスト支払い」を削除しますか？' do
      click_button '削除'
    end

    expect(page).to have_content('まだ立替払いがありません')
  end

  it '確認ダイアログを却下すると削除されない' do
    visit group_show_path(group.token)

    dismiss_confirm '「テスト支払い」を削除しますか？' do
      click_button '削除'
    end

    expect(page).to have_content('テスト支払い')
    expect(payment.reload).to be_persisted
  end
end
