class ActivityLog < ApplicationRecord
  ACTIONS = %w[member.create member.destroy payment.create payment.update payment.destroy].freeze

  belongs_to :group
  belongs_to :subject, polymorphic: true, optional: true

  validates :action, inclusion: { in: ACTIONS }
  validates :subject_type, :subject_id, presence: true

  def self.record(group:, action:, subject:, before: nil, after: nil)
    create!(group:, action:, subject:, before:, after:)
  end

  # 監査ログは追記専用。永続化後の update / destroy を ReadOnlyRecord で弾く
  def readonly?
    persisted?
  end
end
