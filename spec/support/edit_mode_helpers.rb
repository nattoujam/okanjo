# 編集モードのスイッチは sr-only な checkbox なので、Capybara からは label をクリックして操作する
module EditModeHelpers
  def toggle_edit_mode
    find('label', text: '編集モード').click
  end
end

RSpec.configure do |config|
  config.include EditModeHelpers, type: :system
end
