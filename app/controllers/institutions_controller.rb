# frozen_string_literal: true

class InstitutionsController < ApplicationController

  before_action :ensure_logged_in
  before_action :set_institution, only: [:destroy, :edit, :show, :update]
  before_action :authorize_institution, only: [:destroy, :edit, :show, :update]

  ##
  # Responds to POST /institutions
  #
  def create
    @institution = Institution.new(institution_params)
    authorize @institution
    begin
      @institution.save!
    rescue
      render partial: "shared/validation_messages",
             locals: { object: @institution },
             status: :bad_request
    else
      flash['success'] = "Institution \"#{@institution.name}\" created."
      render "shared/reload"
    end
  end

  ##
  # Responds to `DELETE /institutions/:key`
  #
  def destroy
    begin
      @institution.destroy!
    rescue => e
      flash['error'] = "#{e}"
    else
      flash['success'] = "Institution \"#{@institution.name}\" deleted."
    ensure
      redirect_to institutions_path
    end
  end

  ##
  # Responds to `GET /institutions/:key/edit`
  #
  def edit
    render partial: "institutions/form",
           locals: { institution: @institution }
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
  # Responds to `GET /institutions/new`
  #
  def new
    @institution = Institution.new
    authorize @institution
    render partial: "institutions/form",
           locals: { institution: @institution }
  end

  ##
  # Responds to `GET /institutions/:key`
  #
  def show
  end

  ##
  # Responds to `PATCH /institutions/:key`
  #
  def update
    begin
      @institution.update!(institution_params)
    rescue
      render partial: "shared/validation_messages",
             locals: { object: @institution },
             status: :bad_request
    else
      flash['success'] = "Institution \"#{@institution.name}\" updated."
      render "shared/reload"
    end
  end


  private

  def set_institution
    @institution = Institution.find_by_key(params[:key])
    raise ActiveRecord::RecordNotFound unless @institution
    @breadcrumbable = @institution
  end

  def authorize_institution
    @institution ? authorize(@institution) : skip_authorization
  end

  def institution_params
    # Key and name are accepted during creation. For updates, they are
    # overwritten by the contents of org_dn.
    params.require(:institution).permit(:fqdn, :key, :name, :org_dn)
  end

end
