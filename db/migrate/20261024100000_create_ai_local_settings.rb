class CreateAiLocalSettings < ActiveRecord::Migration[6.1]
  def change
    # One row for the whole app: the model served on the operator's machine.
    create_table :ai_local_settings do |t|
      t.boolean :enabled, null: false, default: false
      t.string :base_url
      t.string :model, null: false, default: 'qwen2.5vl:7b'
      t.text :api_key_ciphertext
      t.text :allowed_emails

      t.timestamps
    end

    add_column :users, :admin, :boolean, null: false, default: false
  end
end
