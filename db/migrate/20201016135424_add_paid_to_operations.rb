class AddPaidToOperations < ActiveRecord::Migration[6.0]
  def change
    add_column :operations, :paid, :boolean
  end
end
