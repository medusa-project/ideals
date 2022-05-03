class MakeEmbargoesExpiresAtNullifyable < ActiveRecord::Migration[7.0]
  def change
    change_column_null :embargoes, :expires_at, true
  end
end
