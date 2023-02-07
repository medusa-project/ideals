class AddDepositAgreementColumnToInstitutions < ActiveRecord::Migration[7.0]
  def change
    add_column :institutions, :deposit_agreement, :text
  end
end
