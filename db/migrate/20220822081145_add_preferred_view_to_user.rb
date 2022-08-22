class AddPreferredViewToUser < ActiveRecord::Migration[6.0]
  def change
    add_column :users, :prefered_operations_view, :string
  end
end
