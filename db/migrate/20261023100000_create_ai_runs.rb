class CreateAiRuns < ActiveRecord::Migration[6.1]
  def change
    create_table :ai_runs do |t|
      t.references :user, null: false, foreign_key: true
      t.references :operation, foreign_key: true
      t.string :kind, null: false
      t.string :status, null: false, default: 'processing'
      t.string :provider
      t.string :model
      t.string :prompt_version
      t.jsonb :output, null: false, default: {}
      t.jsonb :raw_response
      t.jsonb :applied_changes, null: false, default: {}
      t.text :error_message
      t.integer :input_tokens
      t.integer :output_tokens
      t.datetime :decided_at

      t.timestamps
    end

    add_index :ai_runs, %i[user_id status]
    add_column :users, :ai_consented_at, :datetime
  end
end
