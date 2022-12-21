class AddUnaccentExtension < ActiveRecord::Migration[7.0]
  def change
    # We lack permission to do this in demo/production so we'll have to do it
    # manually there
    if Rails.env.development? || Rails.env.test?
      execute "CREATE EXTENSION unaccent;"
    end
  end
end
