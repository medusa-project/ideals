# frozen_string_literal: true

class ZipUtils

  ##
  # Returns a list of files contained within a zip file.
  #
  # @param file [String]
  # @return [Enumerable<Hash>] List of hashes with `:name`, `:length`, and
  #                            `:date` keys, ordered by name.
  #
  def self.archived_files(file)
    command  = "unzip -l '#{file}'"
    output, status = Open3.capture2e(command)
    raise "Command returned status code #{status}: #{command}" if status != 0
    # Sample output:
    # Archive:  /path/to/file.zip
    # 31b90daad82cdd7412daea0972ed3df729db5095 (THIS LINE MAY BE MISSING)
    #   Length      Date    Time    Name
    # ---------  ---------- -----   ----
    #         0  10-21-2015 15:26   stuff/     (N.B.: dates may be MM-DD-YYYY or YYYY-MM-DD)
    #      7568  10-21-2015 15:14   stuff/file1
    #       378  10-17-2015 22:32   stuff/file2
    # ---------                     -------
    #      7946                     3 files
    lines        = output.split("\n")
    file1_offset = lines[1].include?("Length") ? 3 : 4
    lines        = lines[file1_offset..(lines.length - 3)]
    files        = lines.map(&:strip).
      reject{ |line| line.end_with?("/") }. # filter out directories
      map{ |line| line.match(/\A(\d+) +([\d-]+) (\d{2}:\d{2}) +(.+)\z/) }.
      map{ |match| {
        name:   match[4],
        length: match[1].to_i,
        date:   "#{match[2]} #{match[3]}" } }.
      sort{ |a,b| a[:name] <=> b[:name] }
    # Transform the string dates into Time objects
    files.each do |f|
      parts = f[:date].match(/(\d+)-(\d+)-(\d+) (\d+):(\d+)/)
      if parts[3].to_s.length == 4 # assume MM-DD-YYYY
        f[:date] = Time.local(parts[3], parts[1], parts[2], parts[4], parts[5])
      else # assume YYYY-MM-DD
        f[:date] = Time.local(parts[1], parts[2], parts[3], parts[4], parts[5])
      end
    end
    files
  end

end