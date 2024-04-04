class AddExpandDepositAgreementColumnToInstitutions < ActiveRecord::Migration[7.1]
  def change
    add_column :institutions, :expand_deposit_agreement, :boolean, default: false, null: false
  end
end
