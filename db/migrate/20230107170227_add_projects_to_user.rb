class AddProjectsToUser < ActiveRecord::Migration[6.0]
  def change
    add_column :todoist_integrations, :project_id, :string
  end
end
