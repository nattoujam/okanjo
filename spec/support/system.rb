# system spec は実ブラウザ (ヘッドレス Chrome) で動かす。
# request spec では検証できない Stimulus / Turbo / アセット配信の退行を捕まえるのが目的。
RSpec.configure do |config|
  config.before(:each, type: :system) do
    driven_by :selenium, using: :headless_chrome, screen_size: [ 1400, 1400 ]
  end
end
