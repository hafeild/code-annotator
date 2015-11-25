require 'test_helper'
include ActionDispatch::TestProcess

class FilesTest < ActionDispatch::IntegrationTest

  def setup
    @user = users(:foo)
    @project = projects(:p1)
  end

  test "user sees error message when adding file that is too big" do
    log_in_as users(:bar)
    project = projects(:p2)

    post "/projects/#{project.id}/files", project_file: {
      files: [fixture_file_upload("files/test.cpp", "text/plain")]
    }

    assert_redirected_to "#{projects_url}/#{project.id}"
    assert_not flash.empty?, "No error messages displayed."
  end

  test "user sees error message when adding a binary file" do
    log_in_as @user

    post "/projects/#{@project.id}/files", project_file: {
      files: [fixture_file_upload("files/test_image.png", "image/png")]
    }

    assert_redirected_to "#{projects_url}/#{@project.id}"
    assert_not flash.empty?, "No error messages displayed."
  end

  test "user gets an error when saving to a non authored project" do
    log_in_as @user
    project = projects(:p2)

    post "/projects/#{project.id}/files", project_file: {
      files: [fixture_file_upload("files/test.cpp", "text/plain")]
    }

    assert_redirected_to root_url
    assert_not flash.empty?, "An error message was displayed: #{flash.to_json}"
  end

  test "no errors when adding a plain text file to a project within size" do
    log_in_as @user

    post "/projects/#{@project.id}/files", project_file: {
      files: [fixture_file_upload("files/test.cpp", "text/plain")]
    }

    assert_redirected_to "#{projects_url}/#{@project.id}##{ProjectFile.last.id}"
    assert flash.empty?, "An error message was displayed: #{flash.to_json}"
  end

end