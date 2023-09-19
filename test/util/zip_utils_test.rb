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
    assert_equal Time.local(2023, 9, 15, 16, 29, 0), files[0][:date]
    assert_equal 574, files[0][:length]
  end

end
