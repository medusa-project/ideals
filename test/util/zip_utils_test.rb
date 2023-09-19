require 'test_helper'

class ZipUtilsTest < ActiveSupport::TestCase

  test "archived_files() raises an error for a non-zip file" do
    file  = file_fixture("crane.jpg")
    assert_raises do
      ZipUtils.archived_files(file)
    end
  end

  test "archived_files() returns a correct list" do
    file  = file_fixture("zip.zip")
    files = ZipUtils.archived_files(file)
    assert_equal 6, files.length
    assert_equal "__MACOSX/._file1.txt", files[0][:name] # lovely
    date = files[0][:date]
    assert_equal 2023, date.year
    assert_equal 9, date.month
    assert_equal 15, date.day
    #assert_equal 16, date.hour
    assert_equal 29, date.min
    assert_equal 574, files[0][:length]
  end

end
