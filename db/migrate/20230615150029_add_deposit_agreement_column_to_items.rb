class AddDepositAgreementColumnToItems < ActiveRecord::Migration[7.0]
  def change
    add_column :items, :deposit_agreement, :text
  end
end
