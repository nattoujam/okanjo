require 'rails_helper'

RSpec.describe '編集モード', type: :system do
  let(:group) { create(:group, name: 'テストグループ') }
  let!(:member) { create(:member, group: group, name: 'メンバーA') }
  let!(:payment) do
    create(:payment, group: group, payer: member, description: 'テスト支払い', participants: [ member ])
  end

  # 表示の切り替えは CSS、状態の保持は Stimulus に任せているので、実ブラウザでしか検証できない
  it '通常モードでは編集・削除の操作を隠す' do
    visit group_show_path(group.token)

    expect(page).to have_content('テスト支払い')
    expect(page).to have_unchecked_field('編集モード', visible: :all)
    expect(page).not_to have_link('編集')
    expect(page).not_to have_button('削除')
    expect(page).not_to have_button('×')
    expect(page).not_to have_field('member[name]')
  end

  it '編集モードに切り替えると編集・削除の操作が現れる' do
    visit group_show_path(group.token)
    toggle_edit_mode

    expect(page).to have_checked_field('編集モード', visible: :all)
    expect(page).to have_link('編集')
    expect(page).to have_button('削除')
    expect(page).to have_button('×')
    expect(page).to have_field('member[name]')

    toggle_edit_mode

    expect(page).to have_unchecked_field('編集モード', visible: :all)
    expect(page).not_to have_button('削除')
  end

  it '立替払いを削除した後も編集モードを維持する' do
    create(:payment, group: group, payer: member, description: 'もう一件', participants: [ member ])
    visit group_show_path(group.token)
    toggle_edit_mode

    accept_confirm '「テスト支払い」を削除しますか？' do
      within('li', text: 'テスト支払い') { click_button '削除' }
    end

    expect(page).not_to have_content('テスト支払い')
    expect(page).to have_checked_field('編集モード', visible: :all)
    expect(page).to have_button('削除')
  end

  it 'グループごとに編集モードを独立して保持する' do
    other_group = create(:group, name: '別グループ')
    create(:member, group: other_group, name: 'メンバーB')

    visit group_show_path(group.token)
    toggle_edit_mode
    expect(page).to have_checked_field('編集モード', visible: :all)

    visit group_show_path(other_group.token)
    expect(page).to have_unchecked_field('編集モード', visible: :all)
    expect(page).not_to have_button('×')

    visit group_show_path(group.token)
    expect(page).to have_checked_field('編集モード', visible: :all)
  end
end
