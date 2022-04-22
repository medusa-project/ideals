##
# Concern to be included by controllers that handle user form submission of
# metadata.
#
module MetadataSubmission

  include ActiveSupport::Concern

  ##
  # Builds and ascribes [AscribedElement]s to an [Item] based on user input.
  # Any existing elements ascribed to the item are deleted. The item is not
  # saved.
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
        item.elements.destroy_all
        name     = nil
        position = 1
        params[:elements].select{ |e| e[:string].present? }.each do |element|
          if name != element[:name]
            name     = element[:name]
            position = 1
          end
          item.elements.build(registered_element: RegisteredElement.find_by_name(element[:name]),
                              string:             element[:string],
                              uri:                element[:uri],
                              position:           position)
          position += 1
        end
      end
    end
  end

end