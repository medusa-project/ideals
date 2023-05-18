class AddGoogleAnalyticsMeasurementIdColumnToInstitutions < ActiveRecord::Migration[7.0]
  def change
    add_column :institutions, :google_analytics_measurement_id, :string
  end
end
