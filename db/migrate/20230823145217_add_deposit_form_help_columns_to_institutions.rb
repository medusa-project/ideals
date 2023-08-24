class AddDepositFormHelpColumnsToInstitutions < ActiveRecord::Migration[7.0]
  def up
    disagreement_help = "The selections you have made indicate that you are "\
      "not ready to deposit your dataset. Our curators are available to "\
      "discuss your dataset with you. Please contact us!"
    collection_help   = "Select the unit into which you would like to "\
      "deposit the item."
    uiuc_collection_help = "IDEALS items are organized by academic unit and "\
      "collection. If you are depositing your own research and unsure which "\
      "collection to deposit into, the Illinois Research and Scholarship "\
      "(Open Collection) can be used."

    add_column :institutions, :deposit_form_disagreement_help, :text, null: false, default: disagreement_help
    add_column :institutions, :deposit_form_collection_help, :text, default: collection_help
    add_column :institutions, :deposit_form_access_help, :text

    execute "UPDATE institutions SET deposit_form_disagreement_help = '#{disagreement_help}';"
    execute "UPDATE institutions SET deposit_form_collection_help = '#{collection_help}' WHERE key != 'uiuc';"
    execute "UPDATE institutions SET deposit_form_collection_help = '#{uiuc_collection_help}' WHERE key = 'uiuc';"
  end

  def down
    remove_column :institutions, :deposit_form_access_help
    remove_column :institutions, :deposit_form_disagreement_help
    remove_column :institutions, :deposit_form_collection_help
  end
end
