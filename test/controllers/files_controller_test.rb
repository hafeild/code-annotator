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
    assert_difference 'ProjectFile.count', 1, "File not added." do 
      post :create, project_id: project.id, project_file: {
        files: [fixture_file_upload("files/test.cpp", "text/plain")]
      }
    end 
  end

end