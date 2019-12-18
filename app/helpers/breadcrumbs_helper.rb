# frozen_string_literal: true

module BreadcrumbsHelper
  def breadcrumbs(object)
    breadcrumbs = object.breadcrumbs
    links = breadcrumbs.map do |breadcrumb|
      link_to(breadcrumb.breadcrumb_label, breadcrumb)
    end
    if object.instance_of? Item
      links.pop
      links << "View Item"
    end
    links.join(" > ").html_safe
  end
end
