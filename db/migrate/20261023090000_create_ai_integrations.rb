class CreateAiIntegrations < ActiveRecord::Migration[6.1]
  def change
    create_table :ai_integrations do |t|
      t.references :user, null: false, foreign_key: true
      t.string :provider, null: false
      t.text :api_key_ciphertext

      t.timestamps
    end

    add_index :ai_integrations, %i[user_id provider], unique: true
  end
end
