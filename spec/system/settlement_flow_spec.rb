require 'rails_helper'

RSpec.describe '割り勘の一連の流れ', type: :system do
  it 'グループ作成から精算結果の確認までできる' do
    visit root_path
    click_link 'グループを作成する'

    fill_in 'グループ名', with: 'テストグループ'
    fill_in 'メモ（任意）', with: 'テストメモ'

    # メンバー欄は Stimulus が hidden field を組み立てるので、JS が動かないと送信されない
    add_member_to_new_form('メンバーA')
    add_member_to_new_form('メンバーB')

    click_button 'グループを作成する'

    expect(page).to have_content('テストグループ')
    expect(page).to have_content('テストメモ')
    expect(page).to have_content('メンバーA')
    expect(page).to have_content('メンバーB')

    # 作成後の画面からもメンバーを追加できる
    toggle_edit_mode
    find("input[name='member[name]']").set('メンバーC')
    click_button '追加'

    expect(page).to have_content('メンバーC')

    click_link '立替払いを追加'

    choose 'メンバーA'
    fill_in '内容', with: 'テスト支払い'
    fill_in '金額', with: 3000
    click_button '追加する'

    # 割り勘対象は初期状態で全員なので、3000円を3人で割る
    expect(page).to have_content('テスト支払い')
    expect(page).to have_content('3,000円')
    expect(page).to have_content('対象: メンバーA, メンバーB, メンバーC')
    expect(page).to have_content('一人あたり')
    expect(page).to have_content('1,000円')

    click_link '精算する'

    expect(page).to have_content('2 回の支払いで精算できます')
    expect(page).to have_content('+2,000円')
    expect(page).to have_content('-1,000円')
  end

  def add_member_to_new_form(name)
    find("input[data-member-form-target='nameInput']").set(name)
    click_button '追加'
  end
end
