# frozen_string_literal: true

##
# Converts {Bitstream}s to other formats and creates alternative versions of
# their attached files.
#
class DerivativeGenerator

  LOGGER = CustomLogger.new(DerivativeGenerator)

  ##
  # @param bitstream [Bitstream]
  #
  def initialize(bitstream)
    @bitstream = bitstream
  end

  def delete_derivatives
    ObjectStore.instance.delete_objects(key_prefix: derivative_key_prefix)
  end

  ##
  # @param region [Symbol] `:full` or `:square`.
  # @param size [Integer]  Size of a square to fit within.
  # @param format [Symbol] Format extension with no leading dot.
  # @return [String]
  #
  def derivative_image_key(region:, size:, format:)
    [derivative_key_prefix, region.to_s, size.to_s,
     "default.#{format}"].join("/")
  end

  ##
  # @param region [Symbol] `:full` or `:square`.
  # @param size [Integer]  Power-of-2 size constraint (128, 256, 512, etc.)
  # @param generate_async [Boolean] Whether to generate the derivative (if
  #                                 necessary) asynchronously. If true, and the
  #                                 image has not already been generated, nil
  #                                 is returned.
  # @return [String] Public URL for a derivative image with the given
  #                  characteristics. If no such image exists, it is generated
  #                  automatically.
  #
  def derivative_image_url(region: :full, size:, generate_async: false)
    unless @bitstream.has_representative_image?
      raise "Derivatives are not supported for this format."
    end
    store = ObjectStore.instance
    key   = derivative_image_key(region: region, size: size, format: :jpg)
    unless store.object_exists?(key: key)
      if generate_async
        task = Task.create!(name: GenerateDerivativeImageJob.to_s)
        GenerateDerivativeImageJob.perform_later(bitstream: @bitstream,
                                                 region:    region,
                                                 size:      size,
                                                 format:    :jpg,
                                                 task:      task)
        return nil
      else
        self.generate_image_derivative(region: region,
                                       size:   size,
                                       format: :jpg)
      end
    end
    store.presigned_download_url(key: key, expires_in: 1.hour.to_i)
  end

  ##
  # @return [String]
  #
  def derivative_key_prefix
    [Bitstream::INSTITUTION_KEY_PREFIX,
     @bitstream.institution.key,
     "derivatives",
     @bitstream.id].join("/")
  end

  ##
  # @return [String]
  #
  def derivative_pdf_key
    [derivative_key_prefix, "pdf", "pdf.pdf"].join("/")
  end

  ##
  # @return [String] Public URL for a derivative PDF with the given
  #                  characteristics. If no such image exists, it is generated
  #                  automatically.
  #
  def derivative_pdf_url
    store  = ObjectStore.instance
    expiry = 1.hour.to_i
    format = @bitstream.format
    if format.media_type == "application/pdf"
      return store.presigned_download_url(key:        @bitstream.effective_key,
                                          expires_in: expiry)
    elsif format.derivative_generator != "libreoffice"
      raise "This instance cannot be converted to PDF."
    end

    key = derivative_pdf_key
    unless store.object_exists?(key: key)
      # TODO: update libreoffice and remove this conditional
      self.generate_pdf_derivative if format.derivative_generator != "libreoffice"
    end
    store.presigned_download_url(key: key, expires_in: expiry)
  end

  ##
  # Downloads the given {Bitstream}'s object into a temp file, writes a
  # derivative image into another temp file, and saves it to the application S3
  # bucket at {derivative_image_key}.
  #
  # @param region [Symbol]
  # @param size [Integer]
  # @param format [Symbol]
  # @param force [Boolean]
  #
  def generate_image_derivative(region:, size:, format:, force: false)
    return if @bitstream.derivative_generation_succeeded == false && !force

    source_tempfile = nil
    deriv_path      = nil
    target_key      = derivative_image_key(region: region,
                                           size:   size,
                                           format: format)
    begin
      Dir.mktmpdir do |tmpdir|
        case @bitstream.format.derivative_generator
        when "imagemagick"
          source_tempfile = @bitstream.download_to_temp_file.path
        when "libreoffice"
          # LibreOffice can convert to images itself, but it doesn't offer very
          # much control over cropping, DPI, etc. Therefore we use it to
          # convert to PDF and then go from there with ImageMagick.
          source_tempfile = generate_pdf_derivative(as_file: true)
        else
          raise "No derivative generator for this format."
        end

        deriv_path = File.join(tmpdir,
                               "#{File.basename(source_tempfile)}-#{region}-#{size}.#{format}")
        crop       = (region == :square) ? "-gravity center -crop 1:1" : ""
        command    = "convert #{source_tempfile}[0] "\
                     "#{crop} "\
                     "-resize #{size}x#{size} "\
                     "-background white "\
                     "-alpha remove "\
                     "#{deriv_path}"
        result     = system(command)
        status     = $?.exitstatus
        raise "Command returned status code #{status}: #{command}" unless result

        File.open(deriv_path, "rb") do |file|
          ObjectStore.instance.put_object(key: target_key, file: file)
        end
      end
    rescue => e
      @bitstream.update!(derivative_generation_succeeded:    false,
                         derivative_generation_attempted_at: Time.now)
      LOGGER.warn("generate_image_derivative(): #{e}")
      raise e
    else
      @bitstream.update!(derivative_generation_succeeded:    true,
                         derivative_generation_attempted_at: Time.now)
    ensure
      FileUtils.rm(source_tempfile) if source_tempfile && File.exist?(source_tempfile)
      FileUtils.rm(deriv_path) if deriv_path && File.exist?(deriv_path)
    end
  end

  ##
  # Downloads the object into a temp file, writes a derivative PDF into another
  # temp file, and saves it to the application S3 bucket at
  # {derivative_pdf_key}.
  #
  # This is used for converting PDF-like formats (e.g. Microsoft Office) into
  # PDFs.
  #
  # @param as_file [Boolean] If true, the PDF is returned as a file path.
  # @param force [Boolean]
  #
  def generate_pdf_derivative(as_file: false, force: false)
    if @bitstream.derivative_generation_succeeded == false && !force
      return
    elsif @bitstream.format.media_types.include?("application/pdf")
      raise "This instance is already a PDF."
    elsif @bitstream.format.derivative_generator != "libreoffice"
      raise "This instance cannot be converted to PDF."
    end
    source_tempfile = @bitstream.download_to_temp_file
    begin
      tmpdir          = File.dirname(source_tempfile)
      command         = "soffice --headless --convert-to pdf "\
        "#{source_tempfile.path} "\
        "--outdir #{tmpdir}"
      output, status = Open3.capture2e(command)
      if status != 0
        raise "Command returned status code #{status}: #{command}\n\nOutput: #{output}"
      end

      pdf_path = File.join(tmpdir,
                           File.basename(source_tempfile).gsub(/#{File.extname(source_tempfile)}\z/, ".pdf"))
      if as_file
        return pdf_path
      else
        File.open(pdf_path, "rb") do |file|
          ObjectStore.instance.put_object(key:  derivative_pdf_key,
                                          file: file)
        end
      end
    rescue => e
      @bitstream.update!(derivative_generation_succeeded:    false,
                         derivative_generation_attempted_at: Time.now)
      LOGGER.warn("generate_pdf_derivative(): #{e}")
      raise e
    else
      @bitstream.update!(derivative_generation_succeeded:    true,
                         derivative_generation_attempted_at: Time.now)
    ensure
      source_tempfile.unlink
    end
  end

end
