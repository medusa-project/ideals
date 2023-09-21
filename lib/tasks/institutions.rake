namespace :institutions do

  desc "Regenerate favicons"
  task :regenerate_favicons => :environment do
    Institution.all.each do |institution|
      begin
        institution.regenerate_favicons
      rescue => e
        puts "Institution #{institution.key}: #{e}"
      end
    end
  end

  ##
  # N.B.: should be run at least monthly
  #
  desc "Rotate institutions' SAML certs"
  task :rotate_saml_certs => :environment do
    Institution.where(saml_auto_cert_rotation: true).
      where.not(saml_sp_public_cert: nil).each do |institution|
      # Check current public cert expiration
      current_cert = OpenSSL::X509::Certificate.new(institution.saml_sp_public_cert)
      expires      = current_cert.not_after
      if expires < 3.months.from_now
        institution.update!(saml_sp_public_cert:      institution.saml_sp_next_public_cert,
                            saml_sp_next_public_cert: nil)
      elsif expires < 1.year.from_now
        new_next_cert = CryptUtils.generate_cert(key:          institution.saml_sp_private_key,
                                                 organization: institution.name,
                                                 common_name:  institution.service_name,
                                                 not_before:   Time.now + 6.months,
                                                 not_after:    Time.now + 6.months + Setting.integer(Setting::Key::SAML_CERT_VALIDITY_YEARS).years)
        institution.update!(saml_sp_next_public_cert: new_next_cert.to_pem)
      end
    end
  end

  desc "Update the auth metadata of all institutions"
  task :update_auth_metadata => :environment do
    # Update the institutions that are federation members
    md_files = {}
    Institution.distinct(:sso_federation).pluck(:sso_federation).select(&:present?).each do |federation|
      md_files[federation] = Institution.fetch_saml_config_metadata(federation: federation)
    end
    Institution.where.not(sso_federation: nil).each do |institution|
      institution.update_from_saml_config_metadata(md_files[institution.sso_federation])
    end
    md_files.each(&:unlink)

    # Update the institutions that are not federation members
    Institution.where.not(saml_config_metadata_url: nil).each do |institution|
      md_file = Institution.fetch_saml_config_metadata(url: institution.saml_config_metadata_url)
      institution.update_from_saml_config_metadata(md_file)
    end
  end

end
