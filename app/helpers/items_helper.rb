module ItemsHelper

  ##
  # @param bitstream [Bitstream]
  # @param show_sysadmin_content [Boolean]
  # @param show_bundle [Boolean] Only relevant when `show_sysadmin_content` is
  #                              `true`.
  # @return [String]
  #
  def bitstream_info(bitstream, show_sysadmin_content: false, show_bundle: true)
    html = StringIO.new
    html << "<div class=\"card mb-3\">"
    html <<   "<div class=\"card-body\">"
    html <<     "<div class=\"float-right\">"
    html <<       "<div class=\"btn-group\" role=\"group\">"

    if policy(bitstream).download?
      html << link_to(item_bitstream_object_path(@item, bitstream), class: "btn btn-sm btn-success") do
        raw("<i class=\"fa fa-download\"></i>"\
        "Download (#{number_to_human_size(bitstream.length)})")
      end
      if show_sysadmin_content
        html << "<button class=\"btn btn-sm btn-light edit-bitstream\""\
            "data-item-id=\"#{bitstream.item_id}\""\
            "data-bitstream-id=\"#{bitstream.id}\""\
            "data-target=\"#edit-bitstream-modal\""\
            "data-toggle=\"modal\""\
            "type=\"button\">"
        html << "<i class=\"fas fa-pencil-alt\"></i> Edit"
      end
      html <<   "</div>"
      html << "</div>"
      html << "<h5 class=\"card-title\">"
      html <<   icon_for(bitstream)
      html <<   " "
      html <<   bitstream.original_filename
      html << "</h5>"
      html << "<dl class=\"files mb-0 mt-3\">"
      html <<   "<dt>Download Count</dt>"
      html <<   "<dd>#{number_with_delimiter(bitstream.download_count)}</dd>"
      if show_sysadmin_content
        html << "<dt>Database ID</dt>"
        html << "<dd>"
        html <<   bitstream.id
        html << "</dd>"
        if show_bundle
          html << "<dt>Bundle</dt>"
          html << "<dd>"
          html <<   Bitstream::Bundle.label(bitstream.bundle)
          html << "</dd>"
        end
        if bitstream.exists_in_staging && bitstream.staging_key
          html << "<dt>Staging Key</dt>"
          html << "<dd><code>"
          html <<   bitstream.staging_key
          html << "</code></dd>"
        else
          html << "<dt>Exists in Staging</dt>"
          html << "<dd>"
          html <<   boolean(false, style: :word)
          html << "</dd>"
        end
        html << "<dt>Submitted For Ingest</dt>"
        html << "<dd>"
        html <<   boolean(bitstream.submitted_for_ingest, style: :word)
        if bitstream.medusa_uuid
          html << "<dt>Medusa UUID</dt>"
          html << "<dd>"
          html <<   link_to(bitstream.medusa_uuid, bitstream.medusa_url)
          html << "</dd>"
          html << "<dt>Medusa Key</dt>"
          html << "<dd><code>"
          html <<   bitstream.medusa_key
          html << "</code></dd>"
        else
          html << "<dt>Exists in Medusa</dt>"
          html << "<dd>"
          html <<   boolean(false, style: :word)
          html << "</dd>"
          html << "<dt>Minimum Access Role</dt>"
          html << "<dd>"
          html <<    Role.label(bitstream.role)
          html << "</dd>"
        end
      end
    end
    html <<   "</div>"
    html << "</div>"
    raw(html.string)
  end

  ##
  # Renders a list of reviewable {Item}s.
  #
  # @param items [Enumerable<Item>] Items grouped by unit and subgrouped by
  #        collection.
  # @param show_tree_headings [Boolean] Whether to show unit/collection tree
  #        headings.
  # @return [String] HTML listing.
  # @see ApplicationHelper#resource_list
  #
  def review_list(items, show_tree_headings: true)
    html = form_tag(items_process_review_path, method: :post, id: "review-form") do
      form = StringIO.new
      form << hidden_field_tag("verb", ""); # value set to approve or reject by JS
      prev_unit = prev_collection = nil
      items.each do |item|
        if show_tree_headings
          # Unit heading
          unit = item.effective_primary_unit
          if prev_unit != unit
            form << "<h2>"
            form << link_to(unit) do
              icon_for(unit) + ' ' + unit.title
            end
            form << "</h2>"
          end
          # Collection heading
          collection = item.effective_primary_collection
          if prev_collection != collection
            form << "<h3 class=\"ml-3\">"
            form <<   "&#8627; "
            form << link_to(collection) do
              icon_for(collection) + ' ' + collection.title
            end
            form << "</h3>"
          end
        end
        form << "<div class=\"media resource-list mb-3 ml-3\">"
        form <<   "<div class=\"check\">"
        form <<     check_box_tag("items[]", item.id)
        form <<   "</div>"
        form <<   "<div class=\"thumbnail ml-2\">"
        form <<     link_to(item) do
          icon_for(item)
        end
        form <<   "</div>"
        form <<   "<div class=\"media-body\">"
        form <<     "<h5 class=\"mt-0 mb-0\">"
        form <<       link_to(item.title, item)
        form <<     "</h5>"
        # Submitter
        form <<     "Submitted by "
        form <<     link_to(item.submitter.becomes(User)) do
          icon_for(item.submitter) + " " + item.submitter.name
        end
        form <<     " on "
        form <<     item.created_at.strftime("%B %d, %Y")
        form <<   "</div>"
        form << "</div>"
        prev_unit       = unit
        prev_collection = collection
      end
      raw(form.string)
    end
    raw(html)
  end

end