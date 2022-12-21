class AddSpatialCoordinatesToInstitutions < ActiveRecord::Migration[7.0]
  def change
    add_column :institutions, :latitude_degrees, :integer, null: true unless column_exists?(:institutions, :latitude_degrees)
    add_column :institutions, :latitude_minutes, :integer, null: true unless column_exists?(:institutions, :latitude_minutes)
    add_column :institutions, :latitude_seconds, :float, null: true unless column_exists?(:institutions, :latitude_seconds)
    add_column :institutions, :longitude_degrees, :integer, null: true unless column_exists?(:institutions, :longitude_degrees)
    add_column :institutions, :longitude_minutes, :integer, null: true unless column_exists?(:institutions, :longitude_minutes)
    add_column :institutions, :longitude_seconds, :float, null: true unless column_exists?(:institutions, :longitude_seconds)
  end
end
