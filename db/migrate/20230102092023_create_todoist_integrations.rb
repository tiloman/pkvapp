class CreateTodoistIntegrations < ActiveRecord::Migration[6.0]
  def change
    create_table :todoist_integrations do |t|
      t.belongs_to :user
      t.string :email
      t.string :password
      t.string :token
      t.timestamps
    end
  end
end
