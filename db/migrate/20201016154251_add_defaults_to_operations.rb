class AddDefaultsToOperations < ActiveRecord::Migration[6.0]
  def change

    change_column :operations, :paid, :boolean, default: false
    change_column :operations, :insurance_paid, :boolean, default: false
    change_column :operations, :insurance_submitted, :boolean, default: false
    change_column :operations, :assistance_paid, :boolean, default: false
    change_column :operations, :assistance_submitted, :boolean, default: false

  end
end
