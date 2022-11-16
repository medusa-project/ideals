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

  # default()

  test "default() returns the default institution" do
    assert_equal institutions(:uiuc), Institution.default
  end

  # favicon_filename()

  test "favicon_filename() returns a correct filename" do
    assert_equal "favicon-128x128.png", Institution.favicon_filename(size: 128)
  end

  # file_sizes()

  test "file_sizes() returns a correct value" do
    sizes = Institution.file_sizes
    assert_equal 1, sizes.count
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
    assert_equal 2, counts.count
  end

  # create()

  test "create() adds default elements" do
    institution = Institution.create!(name:             "New Institution",
                                      service_name:     "New",
                                      key:              "new",
                                      fqdn:             "example.net",
                                      main_website_url: "https://example.net")
    assert_equal 28, institution.registered_elements.count
  end

  test "create() adds a default metadata profile" do
    institution = Institution.create!(name:             "New Institution",
                                      service_name:     "New",
                                      key:              "new",
                                      fqdn:             "example.net",
                                      main_website_url: "https://example.net")
    assert_equal 1, institution.metadata_profiles.count
    profile = institution.metadata_profiles.first
    assert profile.default
    assert profile.elements.count > 0
  end

  test "create() adds a default submission profile" do
    institution = Institution.create!(name:             "New Institution",
                                      service_name:     "New",
                                      key:              "new",
                                      fqdn:             "example.net",
                                      main_website_url: "https://example.net")
    assert_equal 1, institution.submission_profiles.count
    profile = institution.submission_profiles.first
    assert profile.default
    assert profile.elements.count > 0
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

  test "create() adds a defining user group" do
    institution = Institution.create!(name:             "New Institution",
                                      service_name:     "New",
                                      key:              "new",
                                      fqdn:             "example.net",
                                      main_website_url: "https://example.net")
    assert_not_nil institution.defining_user_group
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
    assert @instance.default_metadata_profile.default
  end

  # default_submission_profile()

  test "default_submission_profile() returns the default submission profile" do
    assert @instance.default_submission_profile.default
  end

  # defining_user_group()

  test "defining_user_group() returns the defining user group" do
    assert_not_nil @instance.defining_user_group
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
    assert @instance.favicon_url(size: 128).start_with?("http://")
  end

  test "favicon_url() returns nil when the instance does not have a favicon" do
    @instance.has_favicon = false
    assert_nil @instance.favicon_url(size: 128)
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

  # save()

  test "save() sets all other instances as not-default when the instance is set
  as default" do
    Institution.update_all(default: false)
    @instance = Institution.all.first
    @instance.default = true
    @instance.save!
    assert_equal @instance, Institution.find_by_default(true)
  end

  # service_name

  test "service_name is required" do
    @instance.service_name = nil
    assert !@instance.valid?
  end

  # upload_banner_image()

  test "upload_banner_image() uploads an image" do
    setup_s3
    File.open(file_fixture("escher_lego.jpg"), "r") do |file|
      @instance.upload_banner_image(io: file, extension: "jpg")
    end
    key = Institution.banner_image_key(@instance.key, "jpg")
    assert PersistentStore.instance.object_exists?(key: key)
  end

  test "upload_banner_image() updates the footer_image_filename attribute" do
    setup_s3
    File.open(file_fixture("escher_lego.jpg"), "r") do |file|
      @instance.upload_banner_image(io: file, extension: "jpg")
    end
    assert_equal "banner.jpg", @instance.banner_image_filename
  end

  # upload_favicon()

  test "upload_favicon() uploads favicons" do
    setup_s3
    File.open(file_fixture("escher_lego.jpg"), "r") do |file|
      @instance.upload_favicon(io: file)
    end
    key = "institutions/#{@instance.key}/theme/favicon-original.png"
    assert PersistentStore.instance.object_exists?(key: key)

    InstitutionsHelper::FAVICONS.each do |icon|
      key = "institutions/#{@instance.key}/theme/favicon-#{icon[:size]}x#{icon[:size]}.png"
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
    File.open(file_fixture("escher_lego.jpg"), "r") do |file|
      @instance.upload_favicon(io: file, task: task)
    end
    task.reload
    assert task.succeeded?
  end

  # upload_footer_image()

  test "upload_footer_image() uploads an image" do
    setup_s3
    File.open(file_fixture("escher_lego.jpg"), "r") do |file|
      @instance.upload_footer_image(io: file, extension: "jpg")
    end
    key = Institution.footer_image_key(@instance.key, "jpg")
    assert PersistentStore.instance.object_exists?(key: key)
  end

  test "upload_footer_image() updates the footer_image_filename attribute" do
    setup_s3
    File.open(file_fixture("escher_lego.jpg"), "r") do |file|
      @instance.upload_footer_image(io: file, extension: "jpg")
    end
    assert_equal "footer.jpg", @instance.footer_image_filename
  end

  # upload_header_image()

  test "upload_header_image() uploads an image" do
    setup_s3
    File.open(file_fixture("escher_lego.jpg"), "r") do |file|
      @instance.upload_header_image(io: file, extension: "jpg")
    end
    key = Institution.header_image_key(@instance.key, "jpg")
    assert PersistentStore.instance.object_exists?(key: key)
  end

  test "upload_header_image() updates the header_image_filename attribute" do
    setup_s3
    File.open(file_fixture("escher_lego.jpg"), "r") do |file|
      @instance.upload_header_image(io: file, extension: "jpg")
    end
    assert_equal "header.jpg", @instance.header_image_filename
  end

  # url()

  test "url() returns a correct URL" do
    assert_equal "https://#{@instance.fqdn}", @instance.url
  end

end
