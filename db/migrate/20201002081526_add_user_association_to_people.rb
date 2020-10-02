class AddUserAssociationToPeople < ActiveRecord::Migration[6.0]
  def change
    add_reference :people, :user, index: true
    add_column :users, :first_name, :string
    add_column :users, :last_name, :string
    add_column :users, :mail_reminder, :boolean
    add_column :users, :remind_days_before, :integer
  end
end
