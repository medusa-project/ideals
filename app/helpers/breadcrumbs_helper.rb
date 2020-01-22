# frozen_string_literal: true

module BreadcrumbsHelper

  ##
  # @param object [ApplicationRecord] Model object.
  # @return [String] HTML string.
  #
  def breadcrumbs(object)
    html = StringIO.new
    html << "<nav aria-label=\"breadcrumb\">"
    html <<   "<ol class=\"breadcrumb\">"
    breadcrumbs = object.breadcrumbs
    breadcrumbs.each do |crumb|
      html << "<li class=\"breadcrumb-item\">"
      if crumb.kind_of?(Item)
        html <<   "View Item"
      elsif crumb == breadcrumbs.last
        html <<   crumb.breadcrumb_label
      else
        html <<   link_to(crumb.breadcrumb_label, crumb)
      end
      html << "</li>"
    end
    html <<   "</ol>"
    html << "</nav>"
    raw(html.string)
  end

end
