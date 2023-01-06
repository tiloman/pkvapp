class AddTodoistIdToOperations < ActiveRecord::Migration[6.0]
  def change
    add_column :operations, :todoist_item_id, :string
  end
end
