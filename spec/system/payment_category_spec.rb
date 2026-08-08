require 'rails_helper'

RSpec.describe '立替払いのカテゴリ分類', type: :system do
  let(:group) { create(:group, name: 'GW京都旅行') }
  let!(:member) { create(:member, group: group, name: 'メンバーA') }

  def fill_payment_form(description:, amount:)
    choose 'メンバーA', name: 'payment[payer_member_id]'
    fill_in '内容', with: description
    fill_in '金額', with: amount
  end

  # カテゴリ名の入力欄の開閉は Stimulus に任せているので、実ブラウザでしか検証できない
  it 'カテゴリを新規作成して、以降は既存カテゴリとして選べる' do
    visit new_group_payment_path(group.token)

    expect(page).not_to have_field('payment[new_category_name]')

    select '+ 新しいカテゴリ', from: 'カテゴリ（任意）'
    expect(page).to have_field('payment[new_category_name]')

    fill_in 'payment[new_category_name]', with: '1日目'
    fill_payment_form(description: 'ランチ代', amount: 3600)
    click_button '追加する'

    expect(page).to have_content('1日目')
    expect(page).to have_content('ランチ代')

    click_link '+ 立替払いを追加'
    select '1日目', from: 'カテゴリ（任意）'
    expect(page).not_to have_field('payment[new_category_name]')

    fill_payment_form(description: '交通費', amount: 1400)
    click_button '追加する'

    within_category('1日目') do
      expect(page).to have_content('ランチ代')
      expect(page).to have_content('交通費')
    end
  end

  it 'カテゴリ未選択の立替払いを未分類として最後に表示する' do
    create(:payment, group: group, payer: member, description: '雑費', amount: 1200, participants: [ member ])
    day1 = create(:payment_category, group: group, name: '1日目')
    create(:payment, group: group, payer: member, category: day1, description: 'ランチ代', amount: 3600, participants: [ member ])

    visit group_show_path(group.token)

    expect(page.all('h3').map(&:text)).to eq([ '1日目', '未分類' ])
    within_category('未分類') { expect(page).to have_content('雑費') }
  end

  it 'カテゴリごとの小計を表示する' do
    day1 = create(:payment_category, group: group, name: '1日目')
    create(:payment, group: group, payer: member, category: day1, description: 'ランチ代', amount: 3600, participants: [ member ])
    create(:payment, group: group, payer: member, category: day1, description: '交通費', amount: 1400, participants: [ member ])

    visit group_show_path(group.token)

    expect(find('h3', text: '1日目').find(:xpath, '../span').text).to eq('5,000円')
  end

  it '編集画面からカテゴリを付け替えられる' do
    day1 = create(:payment_category, group: group, name: '1日目')
    create(:payment_category, group: group, name: '2日目')
    payment = create(:payment, group: group, payer: member, category: day1, description: 'ランチ代', participants: [ member ])

    visit edit_group_payment_path(group.token, payment)
    select '2日目', from: 'カテゴリ（任意）'
    click_button '更新する'

    within_category('2日目') { expect(page).to have_content('ランチ代') }
    expect(payment.reload.category.name).to eq('2日目')
  end

  it '立替払いが1件もないカテゴリを小計0円のプレースホルダ付きで表示する' do
    day1 = create(:payment_category, group: group, name: '1日目')
    create(:payment_category, group: group, name: '2日目')
    create(:payment, group: group, payer: member, category: day1, description: 'ランチ代', amount: 3600, participants: [ member ])

    visit group_show_path(group.token)

    expect(page.all('h3').map(&:text)).to eq([ '1日目', '2日目' ])
    within_category('2日目') { expect(page).to have_content('立替払いがありません') }
    expect(find('h3', text: '2日目').find(:xpath, '../span').text).to eq('0円')
  end

  it '最後の立替払いを削除してもカテゴリは残す' do
    day1 = create(:payment_category, group: group, name: '1日目')
    day2 = create(:payment_category, group: group, name: '2日目')
    create(:payment, group: group, payer: member, category: day1, description: 'ランチ代', participants: [ member ])
    create(:payment, group: group, payer: member, category: day2, description: '夕食代', participants: [ member ])

    visit group_show_path(group.token)
    toggle_edit_mode

    accept_confirm '「ランチ代」を削除しますか？' do
      within('li', text: 'ランチ代') { click_button '削除' }
    end

    expect(page).not_to have_content('ランチ代')
    within_category('1日目') { expect(page).to have_content('立替払いがありません') }
  end

  # カテゴリだけが残った状態は「まだ立替払いがありません」に倒す（0円の見出しだけが並ぶのを避ける）
  it '立替払いが1件もないグループではカテゴリの見出しを出さない' do
    create(:payment_category, group: group, name: '1日目')

    visit group_show_path(group.token)

    expect(page).to have_content('まだ立替払いがありません')
    expect(page).not_to have_css('h3')
  end

  describe 'カテゴリの並び替え' do
    let!(:day1) { create(:payment_category, group: group, name: '1日目') }
    let!(:day2) { create(:payment_category, group: group, name: '2日目') }

    before do
      create(:payment, group: group, payer: member, category: day1, description: 'ランチ代', participants: [ member ])
      create(:payment, group: group, payer: member, category: day2, description: '夕食代', participants: [ member ])
      create(:payment, group: group, payer: member, description: '雑費', participants: [ member ])
    end

    # 並び替えは Turbo の再描画を待つ必要があるので、待機する matcher で1件ずつ位置を確かめる
    def expect_category_order(*names)
      names.each_with_index do |name, index|
        expect(page).to have_xpath("(//h3)[#{index + 1}]", text: name)
      end
    end

    it '通常モードでは並び替えの矢印を出さない' do
      visit group_show_path(group.token)

      expect(page).not_to have_button('↑', disabled: :all)
      expect(page).not_to have_button('↓', disabled: :all)
    end

    it '編集モードで矢印を押した方向に1つ入れ替える' do
      visit group_show_path(group.token)
      toggle_edit_mode

      within_category_heading('2日目') { click_button '↑' }
      expect_category_order('2日目', '1日目', '未分類')

      within_category_heading('2日目') { click_button '↓' }
      expect_category_order('1日目', '2日目', '未分類')
    end

    it '立替払いが1件もないカテゴリも並び替えられる' do
      create(:payment_category, group: group, name: '3日目')

      visit group_show_path(group.token)
      toggle_edit_mode

      within_category_heading('3日目') { click_button '↑' }
      expect_category_order('1日目', '3日目', '2日目', '未分類')
    end

    it '端のカテゴリでは行き先のない矢印を押せなくする' do
      visit group_show_path(group.token)
      toggle_edit_mode

      within_category_heading('1日目') { expect(find_button('↑', disabled: true)).to be_present }
      within_category_heading('2日目') { expect(find_button('↓', disabled: true)).to be_present }
    end

    it '未分類には矢印を出さない' do
      visit group_show_path(group.token)
      toggle_edit_mode

      within_category_heading('未分類') do
        expect(page).not_to have_button('↑')
        expect(page).not_to have_button('↓')
      end
    end

    it '並び替えた後も編集モードを維持する' do
      visit group_show_path(group.token)
      toggle_edit_mode

      within_category_heading('2日目') { click_button '↑' }

      expect(page).to have_checked_field('編集モード', visible: :all)
      expect(page).to have_button('↓')
    end
  end

  def within_category_heading(name, &block)
    within(find('h3', text: name).find(:xpath, '..'), &block)
  end

  def within_category(name, &block)
    within(find('h3', text: name).find(:xpath, '../..'), &block)
  end
end
