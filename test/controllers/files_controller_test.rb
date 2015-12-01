require 'test_helper'

class FilesControllerTest < ActionController::TestCase
  def setup
    @user = users(:foo)
  end

  test "should not add file if binary" do
    log_in_as @user
    project = projects(:p1)
    assert_no_difference 'ProjectFile.count', "File added." do 
      post :create, project_id: project.id, project_file: {
        files: [fixture_file_upload("files/test_image.png", "image/png")]
      }
    end 
  end

  test "should not add file if too big" do
    log_in_as users(:bar)
    project = projects(:p2)
    assert_no_difference 'ProjectFile.count', "File added." do 
      post :create, project_id: project.id, project_file: {
        files: [fixture_file_upload("files/test.cpp", "text/plain")]
      }
    end 
  end

  test "should add new file if small enough and plain text" do
    log_in_as @user
    project = projects(:p1)
    assert_difference 'ProjectFile.count', 5, "Files not added." do 
      post :create, project_id: project.id, project_file: {
        files: [
          fixture_file_upload("files/test.cpp", "text/plain"),
          fixture_file_upload("files/data-ascii.dat", "text/plain"),
          fixture_file_upload("files/data-latin1.dat", "text/plain"),
          fixture_file_upload("files/data-utf16.dat", "text/plain"),
          fixture_file_upload("files/data-utf8.dat", "text/plain")
        ]
      }
    end 
  end

end