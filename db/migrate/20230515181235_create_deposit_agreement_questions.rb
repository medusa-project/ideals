class CreateDepositAgreementQuestions < ActiveRecord::Migration[7.0]
  def change
    create_table :deposit_agreement_questions do |t|
      t.bigint :institution_id, null: false
      t.string :text, null: false
      t.string :help_text
      t.integer :position, null: false, default: 0

      t.timestamps
    end
    add_foreign_key :deposit_agreement_questions, :institutions,
                    on_update: :cascade, on_delete: :cascade
    add_index :deposit_agreement_questions, :institution_id
    add_index :deposit_agreement_questions, [:institution_id, :text], unique: true
    add_index :deposit_agreement_questions, [:institution_id, :position], unique: true, name: "index_daq_on_institution_id_and_position"
  end
end
