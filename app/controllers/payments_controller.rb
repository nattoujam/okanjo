class PaymentsController < ApplicationController
  NEW_CATEGORY = "__new__".freeze

  before_action :set_group
  before_action :set_payment, only: [ :edit, :update, :destroy ]

  def new
    @payment = Payment.new
    render :new
  end

  def create
    @payment = @group.payments.build(payment_params)
    @payment.category = resolve_category

    ActiveRecord::Base.transaction do
      @payment.save!
      record_activity("payment.create", after: @payment.audit_snapshot)
    end
    redirect_to group_show_path(@group.token)
  rescue ActiveRecord::RecordInvalid
    render :new, status: :unprocessable_content
  end

  def edit
    render :edit
  end

  def destroy
    ActiveRecord::Base.transaction do
      record_activity("payment.destroy", before: @payment.audit_snapshot)
      @payment.destroy!
    end
    redirect_to group_show_path(@group.token)
  end

  def update
    member_ids = (params.dig(:payment, :member_ids) || []).map(&:to_i)

    if member_ids.empty?
      @payment.errors.add(:base, "割り勘対象者を1人以上選択してください")
      render :edit, status: :unprocessable_content
      return
    end

    before = @payment.audit_snapshot
    ActiveRecord::Base.transaction do
      @payment.update!(payment_base_params.merge(category: resolve_category))
      @payment.payment_participants.destroy_all
      member_ids.each { |id| @payment.payment_participants.create!(member_id: id) }
      # participants の through 関連は before の取得時にキャッシュされているので DB から取り直す
      record_activity("payment.update", before: before, after: @payment.reload.audit_snapshot)
    end
    redirect_to group_show_path(@group.token)
  rescue ActiveRecord::RecordInvalid
    render :edit, status: :unprocessable_content
  end

  private

  def set_group
    @group = Group.includes(:members, :payment_categories).find_by!(token: params[:token])
  end

  def set_payment
    @payment = @group.payments.find(params[:id])
  end

  def record_activity(action, before: nil, after: nil)
    ActivityLog.record(group: @group, action:, subject: @payment, before:, after:)
  end

  # 新規ビルドしたカテゴリは belongs_to の autosave に任せる。
  # 立替払いがバリデーションで落ちたときにカテゴリだけが残るのを防ぐため。
  def resolve_category
    selected = params.dig(:payment, :payment_category_id).to_s
    return @group.payment_categories.find_by(id: selected) unless selected == NEW_CATEGORY

    name = params.dig(:payment, :new_category_name).to_s.strip
    return nil if name.blank?

    @group.payment_categories.find_or_initialize_by(name: name)
  end

  def payment_base_params
    params.require(:payment).permit(:payer_member_id, :description, :amount, :personal_amount)
  end

  def payment_params
    params.require(:payment).permit(:payer_member_id, :description, :amount, :personal_amount, member_ids: [])
      .then { |p| build_payment_params(p) }
  end

  def build_payment_params(p)
    member_ids = p.delete(:member_ids) || []
    p.merge(
      payment_participants_attributes: member_ids.map { |id| { member_id: id } }
    )
  end
end
