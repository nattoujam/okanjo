class MemberRemover
  def initialize(member)
    @member = member
    @group = member.group
  end

  def call
    ActiveRecord::Base.transaction do
      destroyed_payments = @member.paid_payments.to_a
      updated_payments = @member.participated_payments.where.not(payer_member_id: @member.id).to_a
      snapshots_before = updated_payments.to_h { |payment| [ payment, payment.audit_snapshot ] }

      record("member.destroy", @member, before: @member.audit_snapshot)
      destroyed_payments.each { |payment| record("payment.destroy", payment, before: payment.audit_snapshot) }

      @member.destroy!

      updated_payments.each do |payment|
        record("payment.update", payment, before: snapshots_before[payment], after: payment.reload.audit_snapshot)
      end
    end
  end

  private

  def record(action, subject, before: nil, after: nil)
    ActivityLog.record(group: @group, action:, subject:, before:, after:)
  end
end
