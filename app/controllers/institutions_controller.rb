# frozen_string_literal: true

##
# N.B.: Institution properties are split into three categories: properties,
# settings, and theme. Properties can only be edited by sysadmins. The other
# two can be edited by admins of the same institution.
#
class InstitutionsController < ApplicationController

  include Search

  before_action :ensure_institution_host, :ensure_logged_in
  before_action :set_institution, except: [:create, :index, :new]
  before_action :authorize_institution, except: [:create, :index, :new]
  before_action :store_location, only: [:index, :show]

  ##
  # Responds to `POST /institutions`
  #
  def create
    @institution = Institution.new(properties_params)
    authorize @institution
    begin
      @institution.service_name = "New Service"
      @institution.save!
    rescue => e
      render partial: "shared/validation_messages",
             locals: { object: @institution.errors.any? ? @institution : e },
             status: :bad_request
    else
      toast!(title:   "Institution created",
             message: "The \"#{@institution.name}\" institution has been created.")
      render "shared/reload"
    end
  end

  ##
  # Responds to `DELETE /institutions/:key`
  #
  def destroy
    @institution.destroy!
  rescue => e
    flash['error'] = "#{e}"
  else
    toast!(title:   "Institution deleted",
           message: "The \"#{@institution.name}\" institution has been deleted.")
  ensure
    redirect_to institutions_path
  end

  ##
  # Used for editing administering groups.
  #
  # Responds to `GET /institutions/:key/edit-administering-groups` (XHR only)
  #
  def edit_administering_groups
    render partial: "administering_groups_form", locals: { institution: @institution }
  end

  ##
  # Used for editing administering users.
  #
  # Responds to `GET /institutions/:key/edit-administering-users` (XHR only)
  #
  def edit_administering_users
    render partial: "administering_users_form", locals: { institution: @institution }
  end

  ##
  # Used for editing the deposit agreement.
  #
  # Responds to `GET /institutions/:key/edit-deposit-agreement` (XHR only)
  #
  def edit_deposit_agreement
    render partial: "deposit_agreement_form",
           locals: { institution: @institution }
  end

  ##
  # Used for editing the deposit form help text.
  #
  # Responds to `GET /institutions/:key/edit-deposit-help` (XHR only)
  #
  def edit_deposit_help
    render partial: "deposit_help_form",
           locals: { institution: @institution }
  end

  ##
  # Used for editing the deposit questions.
  #
  # Responds to `GET /institutions/:key/edit-deposit-questions` (XHR only)
  #
  def edit_deposit_questions
    render partial: "deposit_questions_form",
           locals: { institution: @institution }
  end

  ##
  # Used for editing element mappings.
  #
  # Responds to `GET /institutions/:key/element-mappings/edit` (XHR only)
  #
  def edit_element_mappings
    render partial: "element_mappings_form",
           locals: { institution: @institution }
  end

  ##
  # Responds to `GET /institutions/:key/edit-local-authentication`
  #
  def edit_local_authentication
    render partial: "institutions/local_authentication_form",
           locals: { institution: @institution }
  end

  ##
  # Responds to `GET /institutions/:key/edit-preservation`
  #
  def edit_preservation
    render partial: "institutions/preservation_form",
           locals: { institution: @institution }
  end

  ##
  # Responds to `GET /institutions/:key/edit-properties`
  #
  def edit_properties
    render partial: "institutions/properties_form",
           locals: { institution: @institution }
  end

  ##
  # Responds to `GET /institutions/:key/edit-saml-authentication`
  #
  def edit_saml_authentication
    render partial: "institutions/saml_authentication_form",
           locals: { institution: @institution }
  end

  ##
  # Responds to `GET /institutions/:key/edit-settings`
  #
  def edit_settings
    render partial: "institutions/settings_form",
           locals: { institution: @institution }
  end

  ##
  # Responds to `GET /institutions/:key/edit-shibboleth-authentication`
  #
  def edit_shibboleth_authentication
    render partial: "institutions/shibboleth_authentication_form",
           locals: { institution: @institution }
  end

  ##
  # Used for editing the theme.
  #
  # Responds to `GET /institutions/:key/edit-theme` (XHR only)
  #
  def edit_theme
    render partial: "theme_form", locals: { institution: @institution }
  end

  ##
  # Responds to `PATCH /institutions/:id/generate-saml-cert`
  #
  def generate_saml_cert
    if @institution.saml_sp_private_key.blank?
      raise "You must supply or generate a private key before you can "\
            "generate a certificate."
    end
    cert = CryptUtils.generate_cert(key:          @institution.saml_sp_private_key,
                                    organization: @institution.name,
                                    common_name:  @institution.service_name,
                                    not_after:    Time.now + Setting.integer(Setting::Key::SAML_CERT_VALIDITY_YEARS, 10).years)
    @institution.update!(saml_sp_public_cert:      cert.to_pem,
                         saml_sp_next_public_cert: nil)
  rescue => e
    flash['error'] = "#{e}"
  else
    toast!(title:   "Certificate generated",
           message: "The SAML SP's public certificate has been updated.")
  ensure
    redirect_back fallback_location: institution_path(@institution)
  end

  ##
  # Responds to `PATCH /institutions/:id/generate-saml-key`
  #
  def generate_saml_key
    key = CryptUtils.generate_key
    @institution.update!(saml_sp_private_key: key.private_to_pem)
  rescue => e
    flash['error'] = "#{e}"
  else
    toast!(title:   "Key generated",
           message: "The SAML SP's private key has been updated.")
  ensure
    redirect_back fallback_location: institution_path(@institution)
  end

  ##
  # Responds to `GET /institutions`
  #
  def index
    authorize Institution
    @institutions    = Institution.all.order(:name)
    @count           = @institutions.count
    @new_institution = Institution.new
  end

  ##
  # Renders a CSV of item download counts by month.
  #
  # Responds to `GET /institutions/:key/item-download-counts`
  #
  def item_download_counts
    @items = MonthlyItemDownloadCount.institution_download_counts_by_item(
      institution: @institution,
      start_year:  params[:from_year].to_i,
      start_month: params[:from_month].to_i,
      end_year:    params[:to_year].to_i,
      end_month:   params[:to_month].to_i)

    # The items array contains item IDs and download counts but not titles.
    # So here we will insert them.
    AscribedElement.
      where(registered_element: current_institution.title_element).
      where(item_id: @items.map{ |row| row['id'] }).pluck(:item_id, :string).each do |asc_e|
      row = @items.find{ |r| r['id'] == asc_e[0] }
      row['title'] = asc_e[1] if row
    end

    respond_to do |format|
      format.html do
        render partial: "show_downloads_by_item"
      end
      format.csv do
        csv = CSV.generate do |csv|
          csv << ["Month", "Downloads"]
          @items.each do |row|
            csv << row.values
          end
        end
        send_data csv,
                  type: "text/csv",
                  disposition: "attachment",
                  filename: "#{@institution.key}_download_counts.csv"
      end
    end
  end

  ##
  # Responds to `GET /institutions/new`
  #
  def new
    @institution = Institution.new
    authorize @institution
    render partial: "institutions/properties_form",
           locals: { institution: @institution }
  end

  ##
  # Handles input from both the "Refresh Configuration Metadata" menu item and
  # "Supply SAML Configuration" modal form.
  #
  # Responds to `PATCH /institutions/:id/refresh-saml-config-metadata`
  #
  def refresh_saml_config_metadata
    task = Task.create!(name: RefreshSamlConfigMetadataJob.to_s)
    if params[:configuration_file].present?
      RefreshSamlConfigMetadataJob.perform_later(institution:        @institution,
                                                 configuration_file: params[:configuration_file],
                                                 user:               current_user,
                                                 task:               task)
    elsif params[:configuration_url].present?
      RefreshSamlConfigMetadataJob.perform_later(institution:       @institution,
                                                 configuration_url: params[:configuration_url],
                                                 user:              current_user,
                                                 task:              task)
    else
      RefreshSamlConfigMetadataJob.perform_later(institution: @institution,
                                                 user:        current_user,
                                                 task:        task)
    end
  rescue => e
    flash['error'] = "#{e}"
  else
    toast!(title: "Refreshing metadata",
           message: "This institution's SAML metadata is being refreshed in "\
                    "the background. Please wait a moment and then reload "\
                    "the page.")
  ensure
    redirect_back fallback_location: @institution
  end

  ##
  # Responds to `DELETE /institutions/:id/banner-image`
  #
  def remove_banner_image
    @institution.delete_banner_image
  rescue => e
    flash['error'] = "#{e}"
  else
    toast!(title:   "Image deleted",
           message: "The banner image has been deleted.")
  ensure
    redirect_back fallback_location: @institution
  end

  ##
  # Responds to `DELETE /institutions/:id/favicon`
  #
  def remove_favicon
    @institution.delete_favicons
  rescue => e
    flash['error'] = "#{e}"
  else
    toast!(title:   "Image deleted",
           message: "The favicons have been deleted.")
  ensure
    redirect_back fallback_location: @institution
  end

  ##
  # Responds to `DELETE /institutions/:id/footer-image`
  #
  def remove_footer_image
    @institution.delete_footer_image
  rescue => e
    flash['error'] = "#{e}"
  else
    toast!(title:   "Image deleted",
           message: "The footer image has been deleted.")
  ensure
    redirect_back fallback_location: @institution
  end

  ##
  # Responds to `DELETE /institutions/:id/header-image`
  #
  def remove_header_image
    @institution.delete_header_image
  rescue => e
    flash['error'] = "#{e}"
  else
    toast!(title:   "Image deleted",
           message: "The header image has been deleted.")
  ensure
    redirect_back fallback_location: @institution
  end

  ##
  # Responds to `GET /institutions/:key`
  #
  def show
    @review_count                  = review_items(0, 0).count
    @submissions_in_progress_count = submissions_in_progress(0, 0).count
    @buried_items_count            = buried_items(0, 0).count
    @embargoed_items_count         = embargoed_items(0, 0).count
    @withdrawn_items_count         = withdrawn_items(0, 0).count
  end

  ##
  # Renders HTML for the access tab in show-institution view.
  #
  # Responds to `GET /institutions/:key/access`
  #
  def show_access
    render partial: "show_access_tab"
  end

  ##
  # Renders HTML for the authentication tab in show-institution view.
  #
  # Responds to `GET /institutions/:key/authentication` (XHR only)
  #
  def show_authentication
    render partial: "show_authentication_tab"
  end

  ##
  # Renders HTML for the deleted items tab in show-institution view.
  #
  # Responds to `GET /institutions/:key/buried-items` (XHR only)
  #
  def show_buried_items
    @permitted_params = params.permit(RESULTS_PARAMS)
    @start            = [@permitted_params[:start].to_i.abs, max_start].min
    @window           = window_size
    @items            = buried_items(@start, @window)
    @count            = @items.count
    @current_page     = @items.page
    render partial: "items/listing"
  end

  ##
  # Renders HTML for the depositing tab in show-institution view.
  #
  # Responds to `GET /institutions/:key/depositing` (XHR only)
  #
  def show_depositing
    render partial: "show_depositing_tab"
  end

  ##
  # Renders HTML for the element mappings tab in show-institution view.
  #
  # Responds to `GET /institutions/:key/element-mappings` (XHR only)
  #
  def show_element_mappings
    render partial: "show_element_mappings_tab"
  end

  ##
  # Renders HTML for the sysadmin-only element namespaces tab in show-
  # institution view.
  #
  # Responds to `GET /institutions/:key/element-namespaces` (XHR only)
  #
  def show_element_namespaces
    @namespaces           = @institution.element_namespaces.order(:prefix)
    @unaccounted_prefixes = @institution.registered_element_prefixes -
      @namespaces.map(&:prefix)
    render partial: "show_element_namespaces_tab"
  end

  ##
  # Renders HTML for the sysadmin-only element registry tab in show-institution
  # view.
  #
  # Responds to `GET /institutions/:key/elements` (XHR only)
  #
  def show_element_registry
    @elements = @institution.registered_elements.order(:label)
    render partial: "show_element_registry_tab"
  end

  ##
  # Renders HTML for the embargoed items tab in show-institution view.
  #
  # Responds to `GET /institutions/:key/embargoed-items` (XHR only)
  #
  def show_embargoed_items
    @permitted_params = params.permit(RESULTS_PARAMS)
    @start            = [@permitted_params[:start].to_i.abs, max_start].min
    @window           = window_size
    @items            = embargoed_items(@start, @window)
    @count            = @items.count
    @current_page     = @items.page
    render partial: "items/listing", locals: { show_embargoed_normally: true }
  end

  ##
  # Renders HTML for the imports tab in show-institution view.
  #
  # Responds to `GET /institutions/:key/imports` (XHR only)
  #
  def show_imports
    authorize Import
    @permitted_params = params.permit(Search::RESULTS_PARAMS +
                                        Search::SIMPLE_SEARCH_PARAMS)
    @start            = [@permitted_params[:start].to_i.abs, max_start].min
    @window           = window_size
    @imports          = Import.
      where(institution: @institution).
      order(created_at: :desc)
    @count            = @imports.count
    @imports          = @imports.limit(@window).offset(@start)
    @current_page     = ((@start / @window.to_f).ceil + 1 if @window > 0) || 1
    render partial: "show_imports_tab"
  end

  ##
  # Renders HTML for the sysadmin-only index pages tab in show-institution view.
  #
  # Responds to `GET /institutions/:key/index-pages` (XHR only)
  #
  def show_index_pages
    @index_pages = @institution.index_pages.order(:name)
    render partial: "show_index_pages_tab"
  end

  ##
  # Renders HTML for the invitees tab in show-institution view.
  #
  # Responds to `GET /institutions/:key/invitees` (XHR only)
  #
  def show_invitees
    @permitted_params = params.permit(Search::RESULTS_PARAMS +
                                        Search::SIMPLE_SEARCH_PARAMS +
                                        [:approval_state, :institution_id])
    @start            = [@permitted_params[:start].to_i.abs, max_start].min
    @window           = window_size
    @invitees         = Invitee.
      where(institution: @institution).
      where("LOWER(email) LIKE ?", "%#{@permitted_params[:q]&.downcase}%").
      where(approval_state: @permitted_params[:approval_state] || Invitee::ApprovalState::PENDING).
      order(:created_at)
    @count            = @invitees.count
    @invitees         = @invitees.limit(@window).offset(@start)
    @current_page     = ((@start / @window.to_f).ceil + 1 if @window > 0) || 1
    @new_invitee      = Invitee.new

    render partial: "show_invitees_tab"
  end

  ##
  # Renders HTML for the sysadmin-only metadata profiles tab in
  # show-institution view.
  #
  # Responds to `GET /institutions/:key/metadata-profiles` (XHR only)
  #
  def show_metadata_profiles
    @profiles = @institution.metadata_profiles.order(:name)
    render partial: "show_metadata_profiles_tab"
  end

  ##
  # Renders HTML for the sysadmin-only prebuilt searches tab in
  # show-institution view.
  #
  # Responds to `GET /institutions/:key/prebuilt-searches` (XHR only)
  #
  def show_prebuilt_searches
    @prebuilt_searches = @institution.prebuilt_searches.order(:name)
    render partial: "show_prebuilt_searches_tab"
  end

  ##
  # Renders HTML for the preservation tab in show-institution view.
  #
  # Responds to `GET /institutions/:key/preservation` (XHR only)
  #
  def show_preservation
    @file_group = @institution.medusa_file_group
    render partial: "show_preservation_tab"
  end

  ##
  # Renders HTML for the properties tab in show-institution view.
  #
  # Responds to `GET /institutions/:key/properties` (XHR only)
  #
  def show_properties
    render partial: "show_properties_tab"
  end

  ##
  # Renders HTML for the review submissions tab in show-show view.
  #
  # Responds to `GET /units/:id/review-submissions`
  #
  def show_review_submissions
    @review_permitted_params = params.permit(Search::RESULTS_PARAMS)
    @review_start            = @review_permitted_params[:start].to_i
    @review_window           = window_size
    @review_items            = review_items(@review_start, @review_window)
    @review_count            = @review_items.count
    @review_current_page     = @review_items.page
    render partial: "collections/show_review_submissions_tab"
  end

  ##
  # Renders HTML for the settings tab in show-institution view.
  #
  # Responds to `GET /institutions/:key/settings` (XHR only)
  #
  def show_settings
    render partial: "show_settings_tab"
  end

  ##
  # Renders HTML for the statistics tab in show-institution view.
  #
  # Responds to `GET /institutions/:key/statistics` (XHR only)
  #
  def show_statistics
    render partial: "show_statistics_tab"
  end

  ##
  # Renders HTML for the sysadmin-only submission profiles tab in
  # show-institution view.
  #
  # Responds to `GET /institutions/:key/submission-profiles` (XHR only)
  #
  def show_submission_profiles
    @profiles = @institution.submission_profiles.order(:name)
    render partial: "show_submission_profiles_tab"
  end

  ##
  # Renders HTML for the submissions-in-progress tab in show-unit view.
  #
  # Responds to `GET /units/:id/submissions-in-progress`
  #
  def show_submissions_in_progress
    @permitted_params = params.permit(Search::RESULTS_PARAMS)
    @start            = [@permitted_params[:start].to_i.abs, max_start].min
    @window           = window_size
    @items            = submissions_in_progress(@start, @window)
    @count            = @items.count
    @current_page     = @items.page
    render partial: "collections/show_submissions_in_progress_tab"
  end

  ##
  # Renders HTML for the theme tab in show-institution view.
  #
  # Responds to `GET /institutions/:key/theme` (XHR only)
  #
  def show_theme
    render partial: "show_theme_tab"
  end

  ##
  # Renders HTML for the sysadmin-only units tab in show-institution view.
  #
  # Responds to `GET /institutions/:key/units` (XHR only)
  #
  def show_units
    @units = Unit.search.
      institution(@institution).
      include_children(false).
      order("#{Unit::IndexFields::TITLE}.sort").
      limit(9999)
    render partial: "show_units_tab"
  end

  ##
  # Renders HTML for the usage tab in show-institution view.
  #
  # Responds to `GET /institutions/:key/usage` (XHR only)
  #
  def show_usage
    @file_sizes       = @institution.file_stats
    @unit_count       = @institution.units.
      where(buried: false).
      count
    @collection_count = Collection.
      where(institution: @institution).
      where(buried: false).
      count
    @item_count       = Item.
      where(institution: @institution).
      where.not(stage: Item::Stages::BURIED).
      count
    @user_count       = @institution.users.count
    render partial: "show_usage_tab"
  end

  ##
  # Renders HTML for the user groups tab in show-institution view.
  #
  # Responds to `GET /institutions/:key/user-groups` (XHR only)
  #
  def show_user_groups
    @user_groups = UserGroup.where(institution: @institution).order(:name)
    render partial: "show_user_groups_tab"
  end

  ##
  # Renders HTML for the users tab in show-institution view.
  #
  # Responds to `GET /institutions/:key/users` (XHR only)
  #
  def show_users
    render partial: "show_users_tab"
  end

  ##
  # Renders HTML for the sysadmin-only vocabularies tab in show-institution
  # view.
  #
  # Responds to `GET /institutions/:key/vocabularies` (XHR only)
  #
  def show_vocabularies
    @permitted_params = params.permit(Search::RESULTS_PARAMS +
                                        Search::SIMPLE_SEARCH_PARAMS +
                                        [:institution_id])
    @start            = [@permitted_params[:start].to_i.abs, max_start].min
    @window           = window_size
    @vocabularies     = Vocabulary.
      where(institution: @institution).
      order(:name)
    @count            = @vocabularies.count
    @vocabularies     = @vocabularies.limit(@window).offset(@start)
    @current_page     = ((@start / @window.to_f).ceil + 1 if @window > 0) || 1
    render partial: "show_vocabularies_tab"
  end

  ##
  # Renders HTML for the withdrawn items tab in show-institution view.
  #
  # Responds to `GET /institutions/:key/withdrawn-items` (XHR only)
  #
  def show_withdrawn_items
    @permitted_params = params.permit(RESULTS_PARAMS)
    @start            = [@permitted_params[:start].to_i.abs, max_start].min
    @window           = window_size
    @items            = withdrawn_items(@start, @window)
    @count            = @items.count
    @current_page     = @items.page
    render partial: "items/listing"
  end

  ##
  # Provides statistics within a date range as CSV.
  #
  # Responds to `GET /institutions/:key/statistics-by-range`
  #
  def statistics_by_range
    begin
      from_time = TimeUtils.ymd_to_time(params[:from_year],
                                        params[:from_month],
                                        params[:from_day])
      to_time   = TimeUtils.ymd_to_time(params[:to_year],
                                        params[:to_month],
                                        params[:to_day])
      # These two queries could probably be consolidated, but this will do for
      # now.
      @counts_by_month = @institution.submitted_item_count_by_month(start_time: from_time,
                                                                    end_time:   to_time)
      downloads_by_month = MonthlyInstitutionItemDownloadCount.for_institution(
        institution: @institution,
        start_year:  params[:from_year].to_i,
        start_month: params[:from_month].to_i,
        end_year:    params[:to_year].to_i,
        end_month:   params[:to_month].to_i)

      @counts_by_month.each_with_index do |m, i|
        m['item_count'] = m['count']
        m['dl_count']   = downloads_by_month[i]['dl_count']
        m.delete('count')
      end
    rescue ArgumentError => e
      render plain: "#{e}", status: :bad_request
      return
    end

    respond_to do |format|
      format.html do
        render partial: "show_statistics_by_month"
      end
      format.csv do
        csv = CSV.generate do |csv|
          csv << ["Month", "Submitted Items", "Downloads"]
          @counts_by_month.each do |row|
            csv << row.values
          end
        end
        send_data csv,
                  type: "text/csv",
                  disposition: "attachment",
                  filename: "#{@institution.key}_statistics.csv"
      end
    end
  end

  ##
  # Responds to `GET /institutions/:key/supply-saml-configuration`
  #
  def supply_saml_configuration
    render partial: "saml_configuration_form",
           locals: { institution: @institution }
  end

  ##
  # Responds to `PATCH /institutions/:key/deposit-agreement-questions`
  #
  def update_deposit_agreement_questions
    begin
      ActiveRecord::Base.transaction do
        @institution.deposit_agreement_questions.destroy_all
        q_count = params[:questions].keys.length
        q_count.times do |q_index|
          pq = params[:questions][q_index.to_s]
          q  = DepositAgreementQuestion.new(institution: @institution,
                                            text:        pq[:text]&.strip,
                                            help_text:   pq[:help_text]&.strip,
                                            position:    q_index)
          r_count = pq[:responses].keys.length
          r_count.times do |r_index|
            pr   = pq[:responses][r_index.to_s]
            text = pr[:text]&.strip
            if text.present?
              q.responses.build(text:     text,
                                success:  pr[:success] == "true",
                                position: r_index)
            end
          end
          q.save!
        end
      end
    rescue => e
      render partial: "shared/validation_messages",
             locals: { object: @institution.errors.any? ? @institution : e },
             status: :bad_request
    else
      toast!(title:   "Questions updated",
             message: "The deposit agreement questions for \"#{@institution.name}\" have been updated.")
      render "shared/reload"
    end
  end

  ##
  # Responds to `PATCH /institutions/:key/preservation`
  #
  def update_preservation
    begin
      ActiveRecord::Base.transaction do
        @institution.update!(preservation_params)
      end
    rescue => e
      render partial: "shared/validation_messages",
             locals:  { object: @institution.errors.any? ? @institution : e },
             status:  :bad_request
    else
      toast!(title:   "Institution updated",
             message: "The \"#{@institution.name}\" institution has been updated.")
      render "shared/reload"
    end
  end

  ##
  # Responds to `PATCH /institutions/:key/properties`
  #
  def update_properties
    begin
      ActiveRecord::Base.transaction do
        @institution.update!(properties_params)
      end
    rescue => e
      render partial: "shared/validation_messages",
             locals: { object: @institution.errors.any? ? @institution : e },
             status: :bad_request
    else
      toast!(title:   "Institution updated",
             message: "The \"#{@institution.name}\" institution has been updated.")
      render "shared/reload"
    end
  end

  ##
  # Responds to `PATCH /institutions/:key/settings`
  #
  def update_settings
    begin
      ActiveRecord::Base.transaction do
        assign_administrators
        upload_images
        @institution.update!(settings_params)
      end
    rescue => e
      render partial: "shared/validation_messages",
             locals: { object: @institution.errors.any? ? @institution : e },
             status: :bad_request
    else
      toast!(title:   "Institution updated",
             message: "The \"#{@institution.name}\" institution has been updated.")
      render "shared/reload"
    end
  end


  private

  def assign_administrators
    # Group administrators
    if params[:user_group_ids]
      @institution.administrator_groups.destroy_all
      params[:user_group_ids].select(&:present?).each do |user_group_id|
        @institution.administrator_groups.build(user_group_id: user_group_id).save!
      end
    end
    # User administrators
    if params[:administering_users]
      @institution.administrators.destroy_all
      params[:administering_users].select(&:present?).each do |user_str|
        user = User.from_autocomplete_string(user_str)
        @institution.errors.add(:administrators,
                                "includes a user that does not exist") unless user
        @institution.administering_users << user
      end
    end
  end

  def set_institution
    @institution = Institution.find_by_key(params[:key] || params[:institution_key])
    raise ActiveRecord::RecordNotFound unless @institution
    @breadcrumbable = @institution
  end

  def authorize_institution
    @institution ? authorize(@institution) : skip_authorization
  end

  def preservation_params
    params.require(:institution).permit(:incoming_message_queue,
                                        :medusa_file_group_id,
                                        :outgoing_message_queue)
  end

  ##
  # N.B.: this is used for both property updates and creates of new
  # institutions. Therefore it must contain all of an instance's required
  # properties, including `service_name`, which is otherwise considered a
  # "setting."
  #
  def properties_params
    params.require(:institution).permit(:fqdn, :key, :latitude_degrees,
                                        :latitude_minutes, :latitude_seconds,
                                        :longitude_degrees, :longitude_minutes,
                                        :longitude_seconds, :name,
                                        :service_name)
  end

  def settings_params
    params.require(:institution).permit(# General Settings tab
                                        :about_html, :about_url,
                                        :copyright_notice, :deposit_agreement,
                                        :earliest_search_year, :feedback_email,
                                        :google_analytics_measurement_id,
                                        :main_website_url, :service_name,
                                        :submissions_reviewed,
                                        :welcome_html,
                                        # Element Mappings tab
                                        :author_element_id,
                                        :date_approved_element_id,
                                        :date_submitted_element_id,
                                        :handle_uri_element_id,
                                        :title_element_id,
                                        # Deposit Agreement tab
                                        :deposit_form_access_help,
                                        :deposit_form_collection_help,
                                        :deposit_form_disagreement_help,
                                        # Authentication tab
                                        :allow_user_registration,
                                        :local_auth_enabled,
                                        :saml_auth_enabled,
                                        :saml_auto_cert_rotation,
                                        :saml_email_attribute,
                                        :saml_email_location,
                                        :saml_idp_encryption_cert,
                                        :saml_idp_encryption_cert2,
                                        :saml_first_name_attribute,
                                        :saml_idp_signing_cert,
                                        :saml_idp_signing_cert2,
                                        :saml_idp_entity_id,
                                        :saml_idp_sso_post_service_url,
                                        :saml_idp_sso_redirect_service_url,
                                        :saml_last_name_attribute,
                                        :saml_sp_entity_id,
                                        :saml_sp_next_public_cert,
                                        :saml_sp_private_key,
                                        :saml_sp_public_cert,
                                        :saml_idp_sso_binding_urn,
                                        :shibboleth_auth_enabled,
                                        :shibboleth_email_attribute,
                                        :shibboleth_extra_attributes,
                                        :shibboleth_host,
                                        :shibboleth_name_attributes,
                                        :shibboleth_org_dn,
                                        :sso_federation,
                                        # Theme tab
                                        :active_link_color,
                                        :banner_image_height,
                                        :footer_background_color,
                                        :header_background_color, :link_color,
                                        :link_hover_color, :primary_color,
                                        :primary_hover_color)
  end

  def upload_images
    p = params[:institution]
    if p[:favicon]
      tempfile = Tempfile.new([SecureRandom.hex,
                               ".#{p[:favicon].original_filename.split(".").last}"])
      tempfile.close
      # We need to pass the temp file's path to an asynchronous job. But our
      # reference to it here will get garbage collected, causing it to get
      # deleted before the job runs, so we have to prevent that from happening.
      # (The job will be responsible for deleting it.)
      ObjectSpace.undefine_finalizer(tempfile)
      File.open(tempfile, "wb") do |file|
        file.write(p[:favicon].read)
      end
      task = Task.create!(name: UploadFaviconsJob.to_s)
      UploadFaviconsJob.perform_later(master_favicon_path: tempfile.path,
                                      institution:         @institution,
                                      user:                current_user,
                                      task:                task)
    end
    if p[:banner_image]
      @institution.upload_banner_image(io:        p[:banner_image],
                                       extension: p[:banner_image].original_filename.split(".").last)
    end
    if p[:footer_image]
      @institution.upload_footer_image(io:        p[:footer_image],
                                       extension: p[:footer_image].original_filename.split(".").last)
    end
    if p[:header_image]
      @institution.upload_header_image(io:        p[:header_image],
                                       extension: p[:header_image].original_filename.split(".").last)
    end
  end

  def buried_items(start, limit)
    Item.search.
      institution(@institution).
      aggregations(false).
      filter(Item::IndexFields::STAGE, Item::Stages::BURIED).
      order(@institution.title_element.indexed_sort_field).
      start(start).
      limit(limit)
  end

  def embargoed_items(start, limit)
    Item.search.
      institution(@institution).
      aggregations(false).
      must_exist(Item::IndexFields::EMBARGOES).
      must_not(Item::IndexFields::STAGE, Item::Stages::WITHDRAWN).
      order(@institution.title_element.indexed_sort_field).
      start(start).
      limit(limit)
  end

  def review_items(start, limit)
    Item.search.
      institution(@institution).
      aggregations(false).
      filter(Item::IndexFields::STAGE, Item::Stages::SUBMITTED).
      filter(Item::IndexFields::INSTITUTION_KEY, @institution.key).
      order(Item::IndexFields::CREATED).
      start(start).
      limit(limit)
  end

  def submissions_in_progress(start, limit)
    Item.search.
      institution(@institution).
      aggregations(false).
      filter(Item::IndexFields::STAGE, Item::Stages::SUBMITTING).
      order(Item::IndexFields::CREATED).
      start(start).
      limit(limit)
  end

  def withdrawn_items(start, limit)
    Item.search.
      institution(@institution).
      aggregations(false).
      filter(Item::IndexFields::STAGE, Item::Stages::WITHDRAWN).
      order(@institution.title_element.indexed_sort_field).
      start(start).
      limit(limit)
  end

end
