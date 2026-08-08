class GroupsController < ApplicationController
  def new
    @group = Group.new
    @groups = Group.order(:id) if Rails.env.development?
    render :new
  end

  def create
    @group = Group.new(group_params)

    if @group.save
      redirect_to group_show_path(@group.token)
    else
      render :new, status: :unprocessable_entity
    end
  end

  def show
    @group = Group.includes(:members, :payment_categories, payments: [ :payer, :payment_participants ]).find_by!(token: params[:token])
    @grouped_payments = group_payments_by_category(@group)
    render :show
  end

  private

  # preload 済みの association で完結させて追加クエリを出さないため、立替払いの新しい順は Ruby 側で並べ替えている
  def group_payments_by_category(group)
    buckets = group.payments.sort_by(&:created_at).reverse.group_by(&:payment_category_id)
    grouped = group.payment_categories.map { |category| [ category, buckets[category.id] || [] ] }
    # 未分類は実体のあるカテゴリではないので、該当する立替払いが無ければ見出しごと出さない
    grouped << [ nil, buckets[nil] ] if buckets[nil].present?
    grouped
  end

  def group_params
    params.require(:group).permit(:name, :memo, members_attributes: [ :name ])
  end
end
