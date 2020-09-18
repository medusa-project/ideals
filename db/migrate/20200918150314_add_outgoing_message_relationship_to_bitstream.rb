class AddOutgoingMessageRelationshipToBitstream < ActiveRecord::Migration[6.0]
  def change
    add_column :outgoing_messages, :bitstream_id, :bigint
    add_foreign_key :outgoing_messages, :bitstreams,
                    column: :bitstream_id,
                    on_update: :cascade,
                    on_delete: :cascade
    # test fixtures may have non-integer bitstream IDs
    execute "UPDATE outgoing_messages SET bitstream_id = CAST(ideals_identifier AS bigint);" unless Rails.env.test?
    remove_column :outgoing_messages, :ideals_class
    remove_column :outgoing_messages, :ideals_identifier
  end
end
