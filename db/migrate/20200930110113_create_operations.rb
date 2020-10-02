class CreateOperations < ActiveRecord::Migration[6.0]
  def change
    create_table :operations do |t|
      t.string :title
      t.float :value
      t.boolean :insurance_paid
      t.boolean :insurance_submitted
      t.boolean :assistance_paid
      t.boolean :assistance_submitted
      t.datetime :billing_date
      t.text :description
      t.belongs_to :person
      t.timestamps
    end
  end
end
