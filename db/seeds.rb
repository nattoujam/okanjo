# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

def create_payment(group:, payer:, description:, amount:, participants:, personal_amount: 0)
  payment = group.payments.build(payer: payer, description: description, amount: amount, personal_amount: personal_amount)
  participants.each { |m| payment.payment_participants.build(member: m) }
  payment.save!
end

# -------------------------------------------------------------------
# パターン1: 精算あり（受取超過・支払い超過が混在する複雑なケース）
# -------------------------------------------------------------------
group1 = Group.find_or_create_by!(token: "seed-demo1", name: "GW京都旅行", memo: "精算あり（複雑）")

if group1.payments.empty?
  tanaka = group1.members.find_or_create_by!(name: "田中")
  suzuki = group1.members.find_or_create_by!(name: "鈴木")
  sato   = group1.members.find_or_create_by!(name: "佐藤")
  ito    = group1.members.find_or_create_by!(name: "伊藤")

  create_payment(group: group1, payer: tanaka, description: "ランチ代",  amount: 8_000,  participants: [ tanaka, suzuki, sato, ito ])
  create_payment(group: group1, payer: suzuki, description: "ホテル代",  amount: 24_000, participants: [ tanaka, suzuki, sato, ito ])
  create_payment(group: group1, payer: sato,   description: "観光バス",  amount: 6_000,  participants: [ tanaka, suzuki, sato ])
  create_payment(group: group1, payer: ito,    description: "夕食代",    amount: 12_000, participants: [ tanaka, suzuki, sato, ito ])
end

# -------------------------------------------------------------------
# パターン2: 精算なし（全員が均等に立替えているケース）
# -------------------------------------------------------------------
group2 = Group.find_or_create_by!(token: "seed-demo2", name: "忘年会", memo: "精算なし（均等割り）")

if group2.members.empty?
  alice = group2.members.create!(name: "Alice")
  bob   = group2.members.create!(name: "Bob")
  carol = group2.members.create!(name: "Carol")

  create_payment(group: group2, payer: alice, description: "1次会",     amount: 9_000, participants: [ alice, bob, carol ])
  create_payment(group: group2, payer: bob,   description: "2次会",     amount: 9_000, participants: [ alice, bob, carol ])
  create_payment(group: group2, payer: carol, description: "タクシー代", amount: 9_000, participants: [ alice, bob, carol ])
end

# -------------------------------------------------------------------
# パターン3: 精算あり（シンプル・1件のみ）
# -------------------------------------------------------------------
group3 = Group.find_or_create_by!(token: "seed-demo3", name: "ランチ割り勘", memo: "精算あり（シンプル）")

if group3.members.empty?
  yamada = group3.members.create!(name: "山田")
  kato   = group3.members.create!(name: "加藤")

  create_payment(group: group3, payer: yamada, description: "ランチ代", amount: 2_600, participants: [ yamada, kato ])
end

# -------------------------------------------------------------------
# パターン4: 精算なし（支払いゼロ）
# -------------------------------------------------------------------
group4 = Group.find_or_create_by!(token: "seed-demo4", name: "計画中グループ", memo: "精算なし（支払いゼロ）")

if group4.members.empty?
  group4.members.create!([ { name: "田中" }, { name: "鈴木" }, { name: "佐藤" } ])
end

# -------------------------------------------------------------------
# パターン5: 端数あり（1100円÷3人 × 独立2グループ）
# -------------------------------------------------------------------
# A が A, B, C 分を 1100円立替 → 1人あたり 366.666... 円
# D が D, E, F 分を 1100円立替 → 1人あたり 366.666... 円
# {A,B,C} と {D,E,F} は独立した精算グループ
# greedy: 4件（{A,B,C} と {D,E,F} を混在させる可能性あり）
# optimal: 4件（独立を保つ）
# -------------------------------------------------------------------
group5 = Group.find_or_create_by!(token: "seed-demo5", name: "端数テスト", memo: "1100円÷3人 × 独立2グループ")

if group5.payments.empty?
  a = group5.members.find_or_create_by!(name: "A")
  b = group5.members.find_or_create_by!(name: "B")
  c = group5.members.find_or_create_by!(name: "C")
  d = group5.members.find_or_create_by!(name: "D")
  e = group5.members.find_or_create_by!(name: "E")
  f = group5.members.find_or_create_by!(name: "F")

  create_payment(group: group5, payer: a, description: "AグループのランチA", amount: 1_100, participants: [ a, b, c ])
  create_payment(group: group5, payer: d, description: "DグループのランチD", amount: 1_100, participants: [ d, e, f ])
end

# -------------------------------------------------------------------
# パターン6: 自分用の金額あり（スーパーでのついで買いを精算対象外にするケース）
# -------------------------------------------------------------------
# 田中がスーパーで5,000円立替え、うち800円は自分用の買い物（精算対象外）
# 精算対象額は4,200円 → 鈴木・佐藤が田中にそれぞれ1,400円払う
group6 = Group.find_or_create_by!(token: "seed-demo6", name: "自炊旅行", memo: "自分用の金額あり（スーパーのついで買い）")

if group6.payments.empty?
  tanaka = group6.members.find_or_create_by!(name: "田中")
  suzuki = group6.members.find_or_create_by!(name: "鈴木")
  sato   = group6.members.find_or_create_by!(name: "佐藤")

  create_payment(group: group6, payer: tanaka, description: "スーパーでの買い出し", amount: 5_000,
                 personal_amount: 800, participants: [ tanaka, suzuki, sato ])
end
