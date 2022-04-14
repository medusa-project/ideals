# frozen_string_literal: true

class FileFormatsController < ApplicationController

  before_action :ensure_logged_in, :authorize_sysadmin

  ##
  # Responds to `GET /file-formats`.
  #
  def index
    sql = "SELECT array_to_string(regexp_matches(LOWER(original_filename),'\\.(\\w+)$'), ', ') AS ext,
          COUNT(id) AS count
      FROM bitstreams
      GROUP BY ext
      ORDER BY count DESC;"
    results = ActiveRecord::Base.connection.exec_query(sql)
    @accounted_formats   = []
    @unaccounted_formats = []
    results.each do |row|
      format = FileFormat.for_extension(row['ext'])
      if format
        found = false
        @accounted_formats.each do |f|
          if f[:format] == format
            f[:count] += 1
            found = true
            break
          end
        end
        unless found
          @accounted_formats << {
            format: format,
            count:  row['count']
          }
        end
      else
        @unaccounted_formats << row
      end
    end
  end


  private

  def authorize_sysadmin
    authorize(FileFormat)
  end

end
