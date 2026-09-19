class SettlementsController < ApplicationController
  REPAYMENT_STRATEGIES = {
    "greedy"  => RepaymentStrategies::Greedy,
    "optimal" => RepaymentStrategies::Optimal
  }.freeze

  # optimal は探索量が人数に対して階乗オーダーで増え、13人規模でもリクエストが返らなくなる。
  # 恒久修正までの暫定措置として選択不可にしている。
  SELECTABLE_ALGOS = %w[greedy].freeze
  DEFAULT_ALGO     = "greedy"

  # 精算結果のキャッシュは solid_cache（永続DB）に入るためデプロイしても消えない。
  # 計算結果が変わる修正を入れたときはここを上げて古いキャッシュを捨てる。
  CACHE_VERSION = "v2".freeze

  def show
    @algo = normalize_algo(params[:algo])
    @selectable_algos = SELECTABLE_ALGOS

    # group + members + payments を常にロード（キャッシュキー生成に必要）
    @group = Group.includes(:members, :payments).find_by!(token: params[:token])
    @repayments, @balances = calculate_settlement(@group, @algo)

    render :show
  end

  def payments_csv
    @group = Group.includes(payments: [ :payer, :category, :participants ]).find_by!(token: params[:token])
    payments = @group.payments.sort_by(&:created_at)

    csv = CSV.generate do |csv|
      csv << %w[日付 カテゴリ 内容 支払者 金額 個人負担額 精算対象額 割り勘対象者]
      payments.each do |p|
        csv << [
          p.created_at.strftime("%Y-%m-%d"),
          p.category&.name || "未分類",
          p.description,
          p.payer.name,
          p.amount,
          p.personal_amount,
          p.split_amount,
          p.participants.map(&:name).join("、")
        ]
      end
    end

    send_csv csv, filename: "立替払い一覧_#{sanitized_group_name(@group)}_#{Date.current.iso8601}.csv"
  end

  def results_csv
    @algo  = normalize_algo(params[:algo])
    @group = Group.includes(:members, :payments).find_by!(token: params[:token])
    repayments, = calculate_settlement(@group, @algo)

    csv = CSV.generate do |csv|
      csv << %w[支払う人 受け取る人 金額]
      repayments.each { |r| csv << [ r[:from].name, r[:to].name, r[:amount] ] }
    end

    send_csv csv, filename: "精算結果_#{sanitized_group_name(@group)}_#{Date.current.iso8601}.csv"
  end

  private

  def normalize_algo(algo)
    SELECTABLE_ALGOS.include?(algo) ? algo : DEFAULT_ALGO
  end

  def sanitized_group_name(group)
    group.name.gsub(%r{[/\\:*?"<>|]}, "_")
  end

  def send_csv(csv_string, filename:)
    send_data csv_string, type: "text/csv; charset=UTF-8", filename: filename, disposition: "attachment"
  end

  # 最終更新時刻だけだと、最新でない立替を削除したときにキーが変わらず古い精算結果を返す。
  # 件数も含めて立替の増減を検知する。
  def payments_cache_key(payments)
    latest = payments.map(&:updated_at).max
    "#{payments.size}-#{latest&.utc&.iso8601(6) || 0}"
  end

  def calculate_settlement(group, algo)
    payments_key   = payments_cache_key(group.payments)
    repayments_key = "settlements/#{CACHE_VERSION}/#{group.token}/#{payments_key}/#{algo}"
    balances_key   = "settlements/#{CACHE_VERSION}/#{group.token}/#{payments_key}/balances"

    raw_repayments = Rails.cache.read(repayments_key)
    raw_balances   = Rails.cache.read(balances_key)

    if raw_repayments.nil? || raw_balances.nil?
      # キャッシュミス: payment_participants を追加ロード（1クエリ）
      ActiveRecord::Associations::Preloader.new(
        records: group.payments.to_a, associations: [ :payment_participants ]
      ).call

      calculator     = RepaymentsCalculator.new(group, strategy: REPAYMENT_STRATEGIES[algo].new)
      raw_repayments = Rails.cache.fetch(repayments_key) { calculator.repayments }
      raw_balances   = Rails.cache.fetch(balances_key)   { calculator.balances.transform_values(&:round) }
    end

    members_by_id = group.members.index_by(&:id)
    repayments = raw_repayments.map { |r| { from: members_by_id[r[:from]], to: members_by_id[r[:to]], amount: r[:amount] } }
    balances   = raw_balances.map   { |id, b| { member: members_by_id[id], balance: b } }
    [ repayments, balances ]
  end
end
