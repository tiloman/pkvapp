class RenameInsuranceNoticeToInsuranceNotices < ActiveRecord::Migration[6.1]
  def up
    ActiveStorage::Attachment
      .where(record_type: "Operation", name: "insurance_notice")
      .update_all(name: "insurance_notices")
  end

  def down
    ActiveStorage::Attachment
      .where(record_type: "Operation", name: "insurance_notices")
      .update_all(name: "insurance_notice")
  end
end
