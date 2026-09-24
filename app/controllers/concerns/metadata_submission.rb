# frozen_string_literal: true

##
# Concern to be included by controllers that handle user form submission of
# metadata.
#
module MetadataSubmission

  include ActiveSupport::Concern

  ##
  # Builds and ascribes {AscribedElement}s to an {Item} based on user input.
  # Any existing elements ascribed to the item are deleted. **The item is not
  # saved.**
  #
  # Submitted metadata is expected to be in the following form (in the params):
  #
  # ```
  # :elements => [
  #   {
  #     :name   => "element_name",
  #     :string => "element string value",
  #     :uri    => "optional element URI value"
  #   }
  # ]
  # ```
  #
  # @param item [Item]
  #
  def build_metadata(item)
    if params[:elements].present?
      ActiveRecord::Base.transaction do
        # Only remove elements that aren't system-managed (e.g. exclude the
        # handle-URI element, date_submitted, date_approved, etc.)
        protected_element_ids = [
          item.institution&.handle_uri_element&.id,
          item.institution&.date_submitted_element&.id,
          item.institution&.date_approved_element&.id
        ].compact
        
        # Destroy only the non-protected elements, then force the association
        # to reload so its in-memory target reflects the current DB state
        # before we build new records onto it.
        item.elements.where.not(registered_element_id: protected_element_ids).destroy_all
        item.association(:elements).reload

        name     = nil
        position = 1

        params[:elements].select{ |e| e[:string].present? }.each do |element|
          if name != element[:name]
            name     = element[:name]
            position = 1
          end
          reg_e = RegisteredElement.where(name:        element[:name],
                                            institution: item.institution).limit(1).first
          # reg_e should never be nil here, but if it is, it would be better to
          # error out (and roll back the transaction) than to discard metadata.
          item.elements.build(registered_element: reg_e,
                              string:             element[:string],
                              uri:                element[:uri],
                              position:           position)
          position += 1
        end
      end
    end
  end
end