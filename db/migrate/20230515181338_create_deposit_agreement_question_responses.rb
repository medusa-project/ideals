class CreateDepositAgreementQuestionResponses < ActiveRecord::Migration[7.0]
  def change
    create_table :deposit_agreement_question_responses do |t|
      t.bigint :deposit_agreement_question_id, null: false
      t.string :text, null: false
      t.integer :position, null: false, default: 0
      t.boolean :success, null: false

      t.timestamps
    end
    add_foreign_key :deposit_agreement_question_responses, :deposit_agreement_questions,
                    on_update: :cascade, on_delete: :cascade
    add_index :deposit_agreement_question_responses, :deposit_agreement_question_id, name: "index_daqr_on_saq_id"
    add_index :deposit_agreement_question_responses, [:deposit_agreement_question_id, :text], name: "index_daqr_on_saq_text"
    add_index :deposit_agreement_question_responses, [:deposit_agreement_question_id, :position], name: "index_daqr_on_saq_position"

    unless Rails.env.test?
      results = execute("SELECT id FROM institutions;")
      results.each do |row|
        institution_id = row['id']
        qid = insert("INSERT INTO deposit_agreement_questions(institution_id, position, text, help_text, created_at, updated_at) "\
                     "VALUES (#{institution_id}, 0, 'Are you a creator of this work or have you been granted permission by the creator to deposit it?', 'The depositor must be the creator of the dataset or have permission to deposit it.', NOW(), NOW())")
        insert("INSERT INTO deposit_agreement_question_responses(deposit_agreement_question_id, position, success, text, created_at, updated_at) "\
               "VALUES (#{qid}, 0, true, 'Yes', NOW(), NOW())")
        insert("INSERT INTO deposit_agreement_question_responses(deposit_agreement_question_id, position, success, text, created_at, updated_at) "\
               "VALUES (#{qid}, 1, false, 'No', NOW(), NOW())")

        qid = insert("INSERT INTO deposit_agreement_questions(institution_id, position, text, help_text, created_at, updated_at) "\
                     "VALUES (#{institution_id}, 1, 'Have you removed any private, confidential, export controlled, or other legally protected information from the submission?', 'Deposit requires removal of any private, confidential, export-controlled, or other legally protected information from the work. A selection of \"Not Applicable\" indicates that the work never included such information, while a selection of ‘Yes’ indicates that such information has been removed.', NOW(), NOW())")
        insert("INSERT INTO deposit_agreement_question_responses(deposit_agreement_question_id, position, success, text, created_at, updated_at) "\
               "VALUES (#{qid}, 0, true, 'Yes', NOW(), NOW())")
        insert("INSERT INTO deposit_agreement_question_responses(deposit_agreement_question_id, position, success, text, created_at, updated_at) "\
               "VALUES (#{qid}, 1, false, 'No', NOW(), NOW())")
        insert("INSERT INTO deposit_agreement_question_responses(deposit_agreement_question_id, position, success, text, created_at, updated_at) "\
               "VALUES (#{qid}, 2, true, 'Not Applicable', NOW(), NOW())")

        qid = insert("INSERT INTO deposit_agreement_questions(institution_id, position, text, help_text, created_at, updated_at) "\
                     "VALUES (#{institution_id}, 2, 'Do you agree to the IDEALS Deposit Agreement in its entirety?', 'Deposit requires agreement to the Deposit Agreement. Click on the Deposit Agreement heading above to view the full agreement.', NOW(), NOW())")
        insert("INSERT INTO deposit_agreement_question_responses(deposit_agreement_question_id, position, success, text, created_at, updated_at) "\
               "VALUES (#{qid}, 0, true, 'Yes', NOW(), NOW())")
        insert("INSERT INTO deposit_agreement_question_responses(deposit_agreement_question_id, position, success, text, created_at, updated_at) "\
               "VALUES (#{qid}, 1, false, 'No', NOW(), NOW())")
      end
    end
  end
end
