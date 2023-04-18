##
# Module to be included by models that are included in UI breadcrumbs.
#
# {ApplicationHelper#breadcrumbs} is responsible for the actual breadcrumb
# rendering.
#
module Breadcrumb
  extend ActiveSupport::Concern

  ##
  # @return [String]
  #
  def breadcrumb_label
    raise "Implementers must override breadcrumb_label()"
  end

  ##
  # Includers can override to provide a breadcrumb parent object. The override
  # can return a Class representing a "first breadcrumb."
  # {ApplicationHelper#breadcrumbs} must recognize this class in order to
  # label and hyperlink it properly.
  #
  # @return [Breadcrumb, Class]
  #
  def breadcrumb_parent
  end

end
