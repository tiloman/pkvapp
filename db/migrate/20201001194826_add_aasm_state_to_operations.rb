class AddAasmStateToOperations < ActiveRecord::Migration[6.0]
  def change
    add_column :operations, :aasm_state, :string
  end
end
