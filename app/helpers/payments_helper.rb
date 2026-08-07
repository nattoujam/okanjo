module PaymentsHelper
  # バリデーションエラーでの再描画時に入力を失わないよう、
  # 未保存の新規カテゴリはセンチネル値＋名前入力欄として復元する
  def selected_category_value(payment)
    payment.category&.new_record? ? PaymentsController::NEW_CATEGORY : payment.payment_category_id
  end

  def new_category_name(payment)
    payment.category.name if payment.category&.new_record?
  end
end
