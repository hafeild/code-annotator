require 'test_helper'

class ProjectsControllerTest < ActionController::TestCase
  def setup
    @user = users(:foo)
    @project = projects(:p1)
  end

  test "should get index when logged in" do
    log_in_as(@user)
    get :index
    assert_response :success
  end

  test "should get show when logged in" do
    log_in_as(@user)
    get :show, id: @project
    assert_response :success
  end

  test "should not be shown unauthorized projects" do
    log_in_as(@user)
    get :show, id: projects(:p2)
    assert_redirected_to projects_url
  end

  test "index should redirect to login when logged out" do
    get :index
    assert_redirected_to login_url
  end

  test "show should redirect to login when logged out" do
    get :show, id: @project
    assert_redirected_to login_url
  end

  test "should be able to download single file" do
    log_in_as @user
    files = [project_files(:file1)]
    response = get :download, project_id: @project, 
      files: {file_ids: files.map{|x| x.id}.join(",")}
    assert_response :success, flash.to_json
    assert response.header["Content-Disposition"] == 
      "attachment; filename=\"#{files[0].name}\""
    assert response.body == files[0].content
  end

  test "should be able to download a directory as a zip" do
    log_in_as @user
    file1 = project_files(:file1)
    files = [project_files(:file1Root)]
    response = get :download, project_id: @project, 
      files: {file_ids: files.map{|x| x.id}.join(",")}
    assert_response :success, flash.to_json
    assert response.header["Content-Disposition"] == 
      "attachment; filename=\"project.zip\""

    ## Check the attachment. Should contain the only  file in the project,
    ## but in a sub folder.
    Zip::InputStream.open(StringIO.new(response.body)) do |io|
      entry = io.get_next_entry
      assert entry.name == file1.path, "Unexpected file."
      assert io.read == file1.content, "Unexpected contents."
      assert io.eof, "EOF not where expected."
    end
  end

  test "shouldn't be able to download file without view access" do
    log_in_as users(:bar)
    files = [project_files(:file1)]
    response = get :download, project_id: @project, 
      files: {file_ids: files.map{|x| x.id}.join(",")}
    assert_response :redirect
    assert_redirected_to root_path
  end

  test "shouldn't be able to download files that span projects" do
    log_in_as @user
    files = [project_files(:file1), project_files(:file3)]
    response = get :download, project_id: @project, 
      files: {file_ids: files.map{|x| x.id}.join(",")}
    assert_response :redirect
    assert_redirected_to root_path
  end

end
