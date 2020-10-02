class AddDeadlineToOperations < ActiveRecord::Migration[6.0]
  def change
  	  add_column :operations, :bill_deadline, :datetime
  	  add_column :operations, :insurance_payback, :float
  	  add_column :operations, :assistance_payback, :float
  end
end
