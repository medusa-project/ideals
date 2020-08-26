class RemoveStagingPathFromMedusaIngests < ActiveRecord::Migration[6.0]
  def change
    remove_column :medusa_ingests, :staging_path
  end
end
