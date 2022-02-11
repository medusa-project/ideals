require 'test_helper'

class ImportJobTest < ActiveSupport::TestCase

  setup do
    setup_s3
  end

  test "perform() runs the CSV importer if the Import has one key ending in
  .csv" do
    import = imports(:csv_new)
    import.upload_file(relative_path: "new.csv",
                       io:            file_fixture("csv/new.csv"))
    kind = ImportJob.new.perform(import, nil)
    assert_equal Import::Kind::CSV, kind
  end

  test "perform() runs the SAF importer if the Import has multiple keys" do
    import = imports(:saf_new)
    kind = ImportJob.new.perform(import, nil)
    assert_equal Import::Kind::SAF, kind
  end

end
