class AddRatioToPerson < ActiveRecord::Migration[6.0]
  def change
  	  add_column :people, :color, :string
  	  add_column :people, :ratio, :string
  end
end
