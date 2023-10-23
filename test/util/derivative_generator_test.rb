require 'test_helper'

class DerivativeGeneratorTest < ActiveSupport::TestCase

  setup do
    setup_s3
    @bitstream = bitstreams(:southeast_item1_in_staging)
    @generator = DerivativeGenerator.new(@bitstream)
  end

  teardown do
    teardown_s3
  end

  # derivative_image_key()

  test "derivative_image_key() returns a correct key" do
    assert_equal [@generator.derivative_key_prefix, "square", "512", "default.jpg"].join("/"),
                 @generator.derivative_image_key(region: :square, size: 512, format: :jpg)
  end

  # derivative_image_url()

  test "derivative_image_url() with an unsupported format raises an error" do
    @bitstream.filename          = "cats.bogus"
    @bitstream.original_filename = "cats.bogus"
    assert_raises do
      @generator.derivative_image_url(size: 45)
    end
  end

  test "derivative_image_url() generates a correct URL using ImageMagick" do
    # upload the source image to the staging area of the application S3 bucket
    File.open(file_fixture("escher_lego.png"), "r") do |file|
      @bitstream.upload_to_staging(file)
    end

    url = @generator.derivative_image_url(size: 45)

    client   = HTTPClient.new
    response = client.get(url)
    assert_equal 200, response.code
    assert response.headers['Content-Length'].to_i > 1000
  end

  test "derivative_image_url() generates a correct URL using LibreOffice" do
    @bitstream = bitstreams(:southwest_unit1_collection1_item1_doc)
    @generator = DerivativeGenerator.new(@bitstream)

    url = @generator.derivative_image_url(size: 45)

    client   = HTTPClient.new
    response = client.get(url)
    assert_equal 200, response.code
    assert response.headers['Content-Length'].to_i > 800
  end

  # derivative_key_prefix()

  test "derivative_key_prefix() returns a correct key" do
    assert_equal [Bitstream::INSTITUTION_KEY_PREFIX,
                  @bitstream.institution.key,
                  "derivatives",
                  @bitstream.id].join("/"),
                 @generator.derivative_key_prefix
  end

  # derivative_pdf_key()

  test "derivative_pdf_key() returns a correct key" do
    assert_equal [@generator.derivative_key_prefix, "pdf", "pdf.pdf"].join("/"),
                 @generator.derivative_pdf_key
  end

  # derivative_pdf_url()

  test "derivative_pdf_url() raises an error for a bitstream that can't be
  represented as PDF" do
    assert_raises do
      @generator.derivative_pdf_url
    end
  end

  test "derivative_pdf_url() returns the URL of a PDF for a bitstream that is
  already a PDF" do
    @bitstream = bitstreams(:southwest_unit1_collection1_item1_pdf)
    @generator = DerivativeGenerator.new(@bitstream)
    url        = @generator.derivative_pdf_url
    response   = HTTPClient.new.get(url)
    assert_equal 200, response.code
    assert response.headers['Content-Length'].to_i > 800
  end

  test "derivative_pdf_url() returns the URL of a PDF for a bitstream that can
  be converted into PDF" do
    @bitstream = bitstreams(:southwest_unit1_collection1_item1_doc)
    @generator = DerivativeGenerator.new(@bitstream)
    url        = @generator.derivative_pdf_url
    response   = HTTPClient.new.get(url)
    assert_equal 200, response.code
    assert response.headers['Content-Length'].to_i > 800
  end

  # generate_image_derivative()

  test "generate_image_derivative() with an unsupported format raises an
  error" do
    @bitstream.filename          = "cats.bogus"
    @bitstream.original_filename = "cats.bogus"
    assert_raises do
      @generator.generate_image_derivative(size: 45)
    end
  end

  test "generate_image_derivative() generates an image using ImageMagick" do
    store = ObjectStore.instance
    key   = @generator.derivative_image_key(region: :full,
                                            size:   512,
                                            format: :jpg)
    assert !store.object_exists?(key: key)
    @generator.generate_image_derivative(region: :full,
                                         size:   512,
                                         format: :jpg)

    assert store.object_exists?(key: key)
  end

  test "generate_image_derivative() generates an image using LibreOffice" do
    @bitstream = bitstreams(:southwest_unit1_collection1_item1_doc)
    @generator = DerivativeGenerator.new(@bitstream)

    store = ObjectStore.instance
    key   = @generator.derivative_image_key(region: :full,
                                            size:   512,
                                            format: :jpg)
    assert !store.object_exists?(key: key)
    @generator.generate_image_derivative(region: :full, size: 512, format: :jpg)
    assert store.object_exists?(key: key)
  end

  test "generate_image_derivative() does nothing if the bitstream's last
  derivative generation attempt failed and the force argument is false" do
    @bitstream.update!(derivative_generation_succeeded: false)

    store = ObjectStore.instance
    key   = @generator.derivative_image_key(region: :full,
                                            size:   512,
                                            format: :jpg)
    @generator.generate_image_derivative(region: :full, size: 512, format: :jpg)
    assert !store.object_exists?(key: key)
  end

  # generate_pdf_derivative()

  test "generate_pdf_derivative() raises an error for a bitstream that can't be
  represented as PDF" do
    assert_raises do
      @generator.generate_pdf_derivative
    end
  end

  test "generate_pdf_derivative() raises an error for a bitstream that cannot
  be converted to PDF" do
    @bitstream = bitstreams(:southwest_unit1_collection1_item1_pdf)
    @generator = DerivativeGenerator.new(@bitstream)

    assert_raises do
      @generator.generate_pdf_derivative
    end
  end

  test "generate_pdf_derivative() generates a PDF for a non-PDF bitstream" do
    @bitstream = bitstreams(:southwest_unit1_collection1_item1_doc)
    @generator = DerivativeGenerator.new(@bitstream)

    store = ObjectStore.instance
    assert !store.object_exists?(key: @generator.derivative_pdf_key)
    @generator.generate_pdf_derivative

    assert store.object_exists?(key: @generator.derivative_pdf_key)
  end

  test "generate_pdf_derivative() does nothing if the bitstream's last
  derivative generation attempt failed and the force argument is false" do
    @bitstream = bitstreams(:southwest_unit1_collection1_item1_doc)
    @bitstream.update!(derivative_generation_succeeded: false)
    @generator = DerivativeGenerator.new(@bitstream)

    store = ObjectStore.instance
    @generator.generate_pdf_derivative

    assert !store.object_exists?(key: @generator.derivative_pdf_key)
  end

end