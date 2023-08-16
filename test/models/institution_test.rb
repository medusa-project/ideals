require 'test_helper'

class InstitutionTest < ActiveSupport::TestCase

  setup do
    @instance = institutions(:southwest)
    assert @instance.valid?
  end

  # banner_image_filename()

  test "banner_image_filename() returns a correct key" do
    assert_equal "banner.png", Institution.banner_image_filename("png")
  end

  # banner_image_key()

  test "banner_image_key() returns a correct key" do
    assert_equal "institutions/test/theme/banner.png",
                 Institution.banner_image_key("test", "png")
  end

  # favicon_filename()

  test "favicon_filename() returns a correct filename" do
    assert_equal "favicon-128x128.png", Institution.favicon_filename(size: 128)
  end

  # fetch_saml_config_metadata()

  test "fetch_saml_config_metadata() raises an error when both arguments are provided" do
    assert_raises ArgumentError do
      Institution.fetch_saml_config_metadata(federation: 99,
                                             url: "https://example.org/")
    end
  end

  test "fetch_saml_config_metadata() raises an error for an unrecognized
  federation" do
    assert_raises ArgumentError do
      Institution.fetch_saml_config_metadata(federation: 52)
    end
  end

  test "fetch_saml_config_metadata() downloads an iTrust XML file" do
    file = Institution.fetch_saml_config_metadata(federation: Institution::SSOFederation::ITRUST)
    assert file.size > 0
  ensure
    File.delete(file)
  end

  test "fetch_saml_config_metadata() downloads an OpenAthens XML file" do
    file = Institution.fetch_saml_config_metadata(federation: Institution::SSOFederation::OPENATHENS)
    assert file.size > 0
  ensure
    File.delete(file)
  end

  test "fetch_saml_config_metadata() downloads a non-federation XML file" do
    file = Institution.fetch_saml_config_metadata(url: "https://www.library.illinois.edu/")
    assert file.size > 0
  ensure
    File.delete(file)
  end

  # file_sizes()

  test "file_sizes() returns a correct value" do
    sizes = Institution.file_sizes
    assert_equal Institution.count, sizes.count
    size = sizes.find{ |row| row['name'] == institutions(:southwest).name }
    assert_not_nil size['count']
    assert_not_nil size['median']
    assert_not_nil size['max']
    assert_not_nil size['sum']
  end

  # footer_image_filename()

  test "footer_image_filename() returns a correct filename" do
    assert_equal "footer.png", Institution.footer_image_filename("png")
  end

  # footer_image_key()

  test "footer_image_key() returns a correct key" do
    assert_equal "institutions/test/theme/footer.png",
                 Institution.footer_image_key("test", "png")
  end

  # header_image_filename()

  test "header_image_filename() returns a correct filename" do
    assert_equal "header.png", Institution.header_image_filename("png")
  end

  # header_image_key()

  test "header_image_key() returns a correct key" do
    assert_equal "institutions/test/theme/header.png",
                 Institution.header_image_key("test", "png")
  end

  # image_key_prefix()

  test "image_key_prefix() returns a correct key" do
    assert_equal "institutions/test/theme/",
                 Institution.image_key_prefix("test")
  end

  # item_counts()

  test "item_counts() returns a correct value" do
    counts = Institution.item_counts
    assert_equal 3, counts.count
  end

  # create()

  test "create() adds default deposit agreement questions" do
    institution = Institution.create!(name:             "New Institution",
                                      service_name:     "New",
                                      key:              "new",
                                      fqdn:             "example.net",
                                      main_website_url: "https://example.net")
    questions = institution.deposit_agreement_questions
    assert_equal 1, questions.length
    q = questions.first
    assert_equal 2, q.responses.length
    r1 = q.responses[0]
    assert_equal "Yes", r1.text
    assert r1.success
    r2 = q.responses[1]
    assert_equal "No", r2.text
    assert !r2.success
  end

  test "create() adds default elements" do
    institution = Institution.create!(name:             "New Institution",
                                      service_name:     "New",
                                      key:              "new",
                                      fqdn:             "example.net",
                                      main_website_url: "https://example.net")
    assert_equal RegisteredElement.where(template: true).count,
                 institution.registered_elements.count
  end

  test "create() adds default element mappings" do
    institution = Institution.create!(name:             "New Institution",
                                      service_name:     "New",
                                      key:              "new",
                                      fqdn:             "example.net",
                                      main_website_url: "https://example.net")
    assert_equal institution.registered_elements.find_by_name("dc:title"),
                 institution.title_element
    assert_equal institution.registered_elements.find_by_name("dc:creator"),
                 institution.author_element
    assert_equal institution.registered_elements.find_by_name("dcterms:dateSubmitted"),
                 institution.date_submitted_element
    assert_equal institution.registered_elements.find_by_name("dcterms:dateAccepted"),
                 institution.date_approved_element
    assert_equal institution.registered_elements.find_by_name("dc:identifier"),
                 institution.handle_uri_element
  end

  test "create() adds default element namespaces" do
    institution = Institution.create!(name:             "New Institution",
                                      service_name:     "New",
                                      key:              "new",
                                      fqdn:             "example.net",
                                      main_website_url: "https://example.net")
    assert_equal 3, institution.element_namespaces.count
  end

  test "create() adds a default index page" do
    institution = Institution.create!(name:             "New Institution",
                                      service_name:     "New",
                                      key:              "new",
                                      fqdn:             "example.net",
                                      main_website_url: "https://example.net")
    assert_equal 1, institution.index_pages.count
    page = institution.index_pages.first
    assert page.registered_elements.count > 0
  end

  test "create() adds a default metadata profile" do
    institution = Institution.create!(name:             "New Institution",
                                      service_name:     "New",
                                      key:              "new",
                                      fqdn:             "example.net",
                                      main_website_url: "https://example.net")
    assert_equal 1, institution.metadata_profiles.count
    profile = institution.metadata_profiles.first
    assert profile.institution_default
    assert_equal institution.registered_elements.count, profile.elements.count
  end

  test "create() adds a default submission profile" do
    institution = Institution.create!(name:             "New Institution",
                                      service_name:     "New",
                                      key:              "new",
                                      fqdn:             "example.net",
                                      main_website_url: "https://example.net")
    assert_equal 1, institution.submission_profiles.count
    profile = institution.submission_profiles.first
    assert profile.institution_default
    assert_equal institution.required_elements.count, profile.elements.count
  end

  test "create() adds default vocabularies" do
    institution = Institution.create!(name:             "New Institution",
                                      service_name:     "New",
                                      key:              "new",
                                      fqdn:             "example.net",
                                      main_website_url: "https://example.net")
    assert_equal 5, institution.vocabularies.count
    vocab = institution.vocabularies.first
    assert vocab.vocabulary_terms.count > 0
  end

  test "create() adds default user groups" do
    institution = Institution.create!(name:             "New Institution",
                                      service_name:     "New",
                                      key:              "new",
                                      fqdn:             "example.net",
                                      main_website_url: "https://example.net")

    # Defining user group
    group = institution.defining_user_group
    assert group.defines_institution
    assert_equal UserGroup::DEFINING_INSTITUTION_KEY, group.key
    assert_equal "#{institution.name} Users", group.name

    # Administrator group
    group = institution.user_groups.find_by_key("#{institution.key}_admin")
    assert !group.defines_institution
    assert_equal "Institution Administrators", group.name
    assert institution.administrator_groups.map(&:user_group).include?(group)
  end

  # active_link_color

  test "active_link_color must contain a valid CSS color" do
    @instance.active_link_color = "#r8z8d8"
    assert !@instance.valid?
    @instance.active_link_color = "#3b7a9c"
    assert @instance.valid?
  end

  test "active_link__color cannot be blank" do
    @instance.active_link_color = ""
    assert !@instance.valid?
    @instance.active_link_color = nil
    assert !@instance.valid?
  end

  # auth_enabled?()

  test "auth_enabled?() returns false if no authentication methods are enabled" do
    @instance.local_auth_enabled = false
    @instance.saml_auth_enabled = false
    @instance.shibboleth_auth_enabled = false
    assert !@instance.auth_enabled?
  end

  test "auth_enabled?() returns false if an authentication method is enabled" do
    @instance.local_auth_enabled = true
    @instance.saml_auth_enabled = false
    @instance.shibboleth_auth_enabled = false
    assert @instance.auth_enabled?
  end

  # banner_image_url()

  test "banner_image_url() returns nil when banner_image is not set" do
    assert_nil @instance.banner_image_url
  end

  test "banner_image_url() returns a correct URL" do
    @instance.banner_image_filename = "banner.png"
    assert @instance.banner_image_url.start_with?("http://")
  end

  # default_metadata_profile()

  test "default_metadata_profile() returns the default metadata profile" do
    assert @instance.default_metadata_profile.institution_default
  end

  # default_submission_profile()

  test "default_submission_profile() returns the default submission profile" do
    assert @instance.default_submission_profile.institution_default
  end

  # defining_user_group()

  test "defining_user_group() returns the defining user group" do
    assert_not_nil @instance.defining_user_group
  end

  # delete_banner_image()

  test "delete_banner_image() deletes the banner image" do
    setup_s3
    File.open(file_fixture("escher_lego.png"), "r") do |file|
      @instance.upload_banner_image(io: file, extension: "jpg")
    end

    @instance.delete_banner_image

    key = Institution.banner_image_key(@instance.key, "jpg")
    assert !PersistentStore.instance.object_exists?(key: key)
  end

  test "delete_banner_image() returns if there is no banner image" do
    @instance.banner_image_filename = nil
    @instance.delete_banner_image
  end

  # delete_favicons()

  test "delete_favicons() deletes the favicons" do
    setup_s3
    File.open(file_fixture("escher_lego.png"), "r") do |file|
      @instance.upload_favicon(io: file)
    end

    @instance.delete_favicons

    key = "institutions/#{@instance.key}/theme/favicons/favicon-original.png"
    assert !PersistentStore.instance.object_exists?(key: key)

    InstitutionsHelper::FAVICONS.each do |icon|
      key = "institutions/#{@instance.key}/theme/favicons/favicon-#{icon[:size]}x#{icon[:size]}.png"
      assert !PersistentStore.instance.object_exists?(key: key)
    end
  end

  test "delete_favicons() returns if there is no favicon" do
    @instance.has_favicon = false
    @instance.delete_favicons
  end

  # delete_footer_image()

  test "delete_footer_image() deletes the footer image" do
    setup_s3
    File.open(file_fixture("escher_lego.png"), "r") do |file|
      @instance.upload_footer_image(io: file, extension: "jpg")
    end

    @instance.delete_footer_image

    key = Institution.footer_image_key(@instance.key, "jpg")
    assert !PersistentStore.instance.object_exists?(key: key)
  end

  test "delete_footer_image() returns if there is no footer image" do
    @instance.footer_image_filename = nil
    @instance.delete_footer_image
  end

  # delete_header_image()

  test "delete_header_image() deletes the header image" do
    setup_s3
    File.open(file_fixture("escher_lego.png"), "r") do |file|
      @instance.upload_header_image(io: file, extension: "jpg")
    end

    @instance.delete_header_image

    key = Institution.header_image_key(@instance.key, "jpg")
    assert !PersistentStore.instance.object_exists?(key: key)
  end

  test "delete_header_image() returns if there is no header image" do
    @instance.header_image_filename = nil
    @instance.delete_header_image
  end

  # download_count_by_month()

  test "download_count_by_month() raises an error if start_time > end_time" do
    assert_raises ArgumentError do
      @instance.download_count_by_month(start_time: Time.now,
                                        end_time:   Time.now - 1.day)
    end
  end

  test "download_count_by_month() returns a correct count" do
    Event.destroy_all
    @instance = institutions(:uiuc)
    expected  = 0
    @instance.units.each do |unit|
      unit.collections.each do |collection|
        collection.items.each do |item|
          item.bitstreams.each do |bitstream|
            bitstream.add_download
            expected += 1
          end
        end
      end
    end
    actual = @instance.download_count_by_month
    assert_equal 1, actual.length
    assert_kind_of Time, actual[0]['month']
    assert_equal expected, actual[0]['dl_count']
  end

  test "download_count_by_month() returns a correct count when supplying start
  and end times" do
    @instance = institutions(:uiuc)
    expected = 0
    @instance.units.each do |unit|
      unit.collections.each do |collection|
        collection.items.each do |item|
          item.bitstreams.each do |bitstream|
            bitstream.add_download
            expected += 1
          end
        end
      end
    end

    # Shift all of the events that were just created 3 months into the past.
    Event.update_all(happened_at: 3.months.ago)

    @instance.units.each do |unit|
      unit.collections.each do |collection|
        collection.items.each do |item|
          item.bitstreams.each do |bitstream|
            bitstream.add_download
          end
        end
      end
    end

    actual = @instance.download_count_by_month(start_time: 4.months.ago,
                                               end_time:   2.months.ago)
    assert_equal 3, actual.length
    assert_kind_of Time, actual[0]['month']
    assert_equal expected, actual[1]['dl_count']
  end

  # favicon_url()

  test "favicon_url() returns a correct URL when the instance has a favicon" do
    @instance.has_favicon = true
    config = ::Configuration.instance
    assert_equal config.storage[:endpoint] + "/" + config.storage[:bucket] +
                   "/institutions/" + @instance.key +
                   "/theme/favicons/favicon-128x128.png",
                 @instance.favicon_url(size: 128)
  end

  test "favicon_url() returns nil when the instance does not have a favicon" do
    @instance.has_favicon = false
    assert_nil @instance.favicon_url(size: 128)
  end

  # feedback_email

  test "feedback_email can be blank" do
    @instance.feedback_email = nil
    assert @instance.valid?
    @instance.feedback_email = ""
    assert @instance.valid?
  end

  test "feedback_email must be a valid email address" do
    @instance.feedback_email = "invalid"
    assert !@instance.valid?
    @instance.feedback_email = "user@example.org"
    assert @instance.valid?
  end

  # file_stats()

  test "file_stats() returns file statistics" do
    stats = @instance.file_stats
    assert stats[:count] > 0
    assert stats[:sum] > 0
    assert stats[:mean] > 0
    assert stats[:median] > 0
    assert stats[:max] > 0
  end

  # footer_background_color

  test "footer_background_color must contain a valid CSS color" do
    @instance.footer_background_color = "#r8z8d8"
    assert !@instance.valid?
    @instance.footer_background_color = "#3b7a9c"
    assert @instance.valid?
  end

  test "footer_background_color cannot be blank" do
    @instance.footer_background_color = ""
    assert !@instance.valid?
    @instance.footer_background_color = nil
    assert !@instance.valid?
  end

  # footer_image_url()

  test "footer_image_url() returns nil when footer_image is not set" do
    assert_nil @instance.footer_image_url
  end

  test "footer_image_url() returns a correct URL" do
    @instance.footer_image_filename = "footer.png"
    assert @instance.footer_image_url.start_with?("http://")
  end

  # fqdn

  test "fqdn must be present" do
    @instance.fqdn = nil
    assert !@instance.valid?
    @instance.fqdn = ""
    assert !@instance.valid?
  end

  # header_background_color

  test "header_background_color must contain a valid CSS color" do
    @instance.header_background_color = "#r8z8d8"
    assert !@instance.valid?
    @instance.header_background_color = "#3b7a9c"
    assert @instance.valid?
  end

  test "header_background_color cannot be blank" do
    @instance.header_background_color = ""
    assert !@instance.valid?
    @instance.header_background_color = nil
    assert !@instance.valid?
  end

  # header_image_url()

  test "header_image_url() returns nil when header_image is not set" do
    assert_nil @instance.header_image_url
  end

  test "header_image_url() returns a correct URL" do
    @instance.header_image_filename = "header.png"
    assert @instance.header_image_url.start_with?("http://")
  end

  # key

  test "key must be present" do
    assert_raises ActiveRecord::RecordInvalid do
      Institution.create!(name:         "Valid",
                          fqdn:         "example.net",
                          service_name: "Valid")
    end
    assert_raises ActiveRecord::RecordInvalid do
      Institution.create!(key:          "",
                          name:         "Valid",
                          fqdn:         "example.net",
                          service_name: "Valid")
    end
  end

  test "key must be alphanumeric" do
    assert_raises ActiveRecord::RecordInvalid do
      Institution.create!(key:          "invalid!",
                          name:         "Invalid",
                          fqdn:         "example.org",
                          service_name: "Invalid")
    end
    Institution.create!(key:          "valid",
                        name:         "Valid",
                        fqdn:         "example.net",
                        service_name: "Valid")
  end

  test "key cannot be changed" do
    assert_raises ActiveRecord::RecordInvalid do
      @instance.update!(key: "newvalue")
    end
  end

  # latitude_degrees

  test "latitude_degrees must be within the Illinois boundaries" do
    @instance.latitude_degrees = 35
    assert !@instance.valid?
    @instance.latitude_degrees = 45
    assert !@instance.valid?
    @instance.latitude_degrees = 40
    assert @instance.valid?
  end

  # link_color

  test "link_color must contain a valid CSS color" do
    @instance.link_color = "#r8z8d8"
    assert !@instance.valid?
    @instance.link_color = "#3b7a9c"
    assert @instance.valid?
  end

  test "link__color cannot be blank" do
    @instance.link_color = ""
    assert !@instance.valid?
    @instance.link_color = nil
    assert !@instance.valid?
  end

  # link_hover_color

  test "link_hover_color must contain a valid CSS color" do
    @instance.link_hover_color = "#r8z8d8"
    assert !@instance.valid?
    @instance.link_hover_color = "#3b7a9c"
    assert @instance.valid?
  end

  test "link_hover_color cannot be blank" do
    @instance.link_hover_color = ""
    assert !@instance.valid?
    @instance.link_hover_color = nil
    assert !@instance.valid?
  end

  # longitude_degrees

  test "longitude_degrees must be within the Illinois boundaries" do
    @instance.longitude_degrees = -92
    assert !@instance.valid?
    @instance.longitude_degrees = -84
    assert !@instance.valid?
    @instance.longitude_degrees = -88
    assert @instance.valid?
  end

  # medusa_file_group()

  test "medusa_file_group() returns an instance when medusa_file_group_id is set" do
    @instance.medusa_file_group_id = 50
    assert_equal @instance.medusa_file_group_id, @instance.medusa_file_group.id
  end

  test "medusa_file_group() returns nil when medusa_file_group_id is not set" do
    assert_nil @instance.medusa_file_group
  end

  # medusa_file_group_id

  test "medusa_file_group_id must be an integer" do
    @instance.medusa_file_group_id = 3
    assert @instance.valid?
    @instance.medusa_file_group_id = "string"
    assert !@instance.valid?
  end

  test "medusa_file_group_id must be unique" do
    @instance.update!(medusa_file_group_id: 3)
    assert_raises do
      institutions(:northeast).update!(medusa_file_group_id: 3)
    end
  end

  # name

  test "name must be present" do
    @instance.name = nil
    assert !@instance.valid?
    @instance.name = ""
    assert !@instance.valid?
  end

  # nuke!()

  test "nuke!() nukes an instance" do
    setup_opensearch
    @instance.nuke!
    assert @instance.destroyed?
  end

  # primary_color

  test "primary_color must contain a valid CSS color" do
    @instance.primary_color = "#r8z8d8"
    assert !@instance.valid?
    @instance.primary_color = "#3b7a9c"
    assert @instance.valid?
  end

  test "primary_color cannot be blank" do
    @instance.primary_color = ""
    assert !@instance.valid?
    @instance.primary_color = nil
    assert !@instance.valid?
  end

  # primary_hover_color

  test "primary_hover_color must contain a valid CSS color" do
    @instance.primary_hover_color = "#r8z8d8"
    assert !@instance.valid?
    @instance.primary_hover_color = "#3b7a9c"
    assert @instance.valid?
  end

  test "primary_hover_color cannot be blank" do
    @instance.primary_hover_color = ""
    assert !@instance.valid?
    @instance.primary_hover_color = nil
    assert !@instance.valid?
  end

  # public_item_count()

  test "public_item_count() returns a correct value" do
    setup_opensearch
    Item.reindex_all
    assert_equal 0, @instance.public_item_count
  end

  # regenerate_favicons()

  test "regenerate_favicons()" do
    setup_s3
    # Upload a favicon and all of its derivatives.
    File.open(file_fixture("escher_lego.png"), "r") do |file|
      @instance.upload_favicon(io: file)
    end
    # Delete its derivatives.
    InstitutionsHelper::FAVICONS.each do |icon|
      key = "institutions/#{@instance.key}/theme/favicons/favicon-#{icon[:size]}x#{icon[:size]}.png"
      PersistentStore.instance.delete_object(key: key)
    end
    # Regenerate them.
    @instance.regenerate_favicons
    # Assert that they have all been generated.
    InstitutionsHelper::FAVICONS.each do |icon|
      key = "institutions/#{@instance.key}/theme/favicons/favicon-#{icon[:size]}x#{icon[:size]}.png"
      assert PersistentStore.instance.object_exists?(key: key)
    end
  end

  test "regenerate_favicons() succeeds the given Task" do
    setup_s3
    task = Task.create!(name:          self.class.name,
                        institution:   @instance,
                        indeterminate: false,
                        started_at:    Time.now,
                        status_text:   "Regenerating favicons")
    File.open(file_fixture("escher_lego.png"), "r") do |file|
      @instance.upload_favicon(io: file)
      @instance.regenerate_favicons(task: task)
    end
    task.reload
    assert task.succeeded?
  end

  # registered_element_prefixes()

  test "registered_element_prefixes() returns all registered element
  prefixes" do
    assert_equal %w[dc dcterms thesis],
                 @instance.registered_element_prefixes
  end

  # required_elements

  test "required_elements() returns system-required elements" do
    assert_equal 2, @instance.required_elements.length
  end

  # saml_email_location

  test "saml_email_location must be one of the SAMLEmailLocation constant
  values" do
    @instance.saml_email_location = Institution::SAMLEmailLocation::NAMEID
    assert @instance.valid?
    @instance.saml_email_location = Institution::SAMLEmailLocation::ATTRIBUTE
    assert @instance.valid?
    @instance.saml_email_location = 99
    assert !@instance.valid?
  end

  # saml_sp_entity_id()

  test "saml_sp_entity_id() returns a correct value" do
    assert_equal "#{@instance.scope_url}/entity", @instance.saml_sp_entity_id
  end

  # scope_url()

  test "scope_url() returns a correct value" do
    assert_equal "http://#{@instance.fqdn}", @instance.scope_url
  end

  # service_name

  test "service_name is required" do
    @instance.service_name = nil
    assert !@instance.valid?
  end

  # shibboleth_extra_attributes

  test "shibboleth_extra_attributes can be set to a CSV string" do
    @instance.update!(shibboleth_extra_attributes: "dogs, cats, foxes")
    assert_equal %w(dogs cats foxes), @instance.shibboleth_extra_attributes
  end

  # update_from_saml_config_metadata()

  test "update_from_saml_config_metadata() raises an error if there is no
  matching entityID in the XML file" do
    @instance.fqdn = "bogus.org"
    xml_file = file_fixture("oaf_metadata.xml")

    assert_raises do
      @instance.update_from_saml_config_metadata(xml_file)
    end
  end

  test "update_from_saml_config_metadata() updates properties from OAF
  metadata" do
    @instance.saml_idp_sso_service_url = nil
    @instance.saml_idp_cert            = nil
    xml_file = file_fixture("oaf_metadata.xml")

    @instance.update_from_saml_config_metadata(xml_file)
    assert_equal "https://login.openathens.net/saml/2/sso/southwest.edu",
                 @instance.saml_idp_sso_service_url
    assert @instance.saml_idp_cert.starts_with?("-----BEGIN CERTIFICATE-----\n")
    assert @instance.saml_idp_cert.ends_with?("\n-----END CERTIFICATE-----")
  end

  # upload_banner_image()

  test "upload_banner_image() uploads an image" do
    setup_s3
    File.open(file_fixture("escher_lego.png"), "r") do |file|
      @instance.upload_banner_image(io: file, extension: "jpg")
    end
    key = Institution.banner_image_key(@instance.key, "jpg")
    assert PersistentStore.instance.object_exists?(key: key)
  end

  test "upload_banner_image() updates the footer_image_filename attribute" do
    setup_s3
    File.open(file_fixture("escher_lego.png"), "r") do |file|
      @instance.upload_banner_image(io: file, extension: "jpg")
    end
    assert_equal "banner.jpg", @instance.banner_image_filename
  end

  # upload_favicon()

  test "upload_favicon() uploads favicons" do
    setup_s3
    File.open(file_fixture("escher_lego.png"), "r") do |file|
      @instance.upload_favicon(io: file)
    end
    key = "institutions/#{@instance.key}/theme/favicons/favicon-original.png"
    assert PersistentStore.instance.object_exists?(key: key)

    InstitutionsHelper::FAVICONS.each do |icon|
      key = "institutions/#{@instance.key}/theme/favicons/favicon-#{icon[:size]}x#{icon[:size]}.png"
      assert PersistentStore.instance.object_exists?(key: key)
    end
  end

  test "upload_favicon() succeeds the given Task" do
    setup_s3
    task = Task.create!(name:          self.class.name,
                        institution:   @instance,
                        indeterminate: false,
                        started_at:    Time.now,
                        status_text:   "Processing favicons")
    File.open(file_fixture("escher_lego.png"), "r") do |file|
      @instance.upload_favicon(io: file, task: task)
    end
    task.reload
    assert task.succeeded?
  end

  # upload_footer_image()

  test "upload_footer_image() uploads an image" do
    setup_s3
    File.open(file_fixture("escher_lego.png"), "r") do |file|
      @instance.upload_footer_image(io: file, extension: "jpg")
    end
    key = Institution.footer_image_key(@instance.key, "jpg")
    assert PersistentStore.instance.object_exists?(key: key)
  end

  test "upload_footer_image() updates the footer_image_filename attribute" do
    setup_s3
    File.open(file_fixture("escher_lego.png"), "r") do |file|
      @instance.upload_footer_image(io: file, extension: "jpg")
    end
    assert_equal "footer.jpg", @instance.footer_image_filename
  end

  # upload_header_image()

  test "upload_header_image() uploads an image" do
    setup_s3
    File.open(file_fixture("escher_lego.png"), "r") do |file|
      @instance.upload_header_image(io: file, extension: "jpg")
    end
    key = Institution.header_image_key(@instance.key, "jpg")
    assert PersistentStore.instance.object_exists?(key: key)
  end

  test "upload_header_image() updates the header_image_filename attribute" do
    setup_s3
    File.open(file_fixture("escher_lego.png"), "r") do |file|
      @instance.upload_header_image(io: file, extension: "jpg")
    end
    assert_equal "header.jpg", @instance.header_image_filename
  end

  # url()

  test "url() returns a correct URL" do
    assert_equal "https://#{@instance.fqdn}", @instance.url
  end

end
