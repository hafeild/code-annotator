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

  test "should get show when accessing a public link" do
    log_in_as(users(:bar))
    get :show_public, link_uuid: "alink"
    assert_response :success
  end

  test "should not get show when accessing an invalid public link" do
    log_in_as(users(:bar))
    get :show_public, link_uuid: "abadlink"
    assert_redirected_to home_url
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




  test "should return success message on project create with zip file" do
    log_in_as @user
    assert_difference 'Project.count', 1, "Project not added" do 
      assert_difference 'ProjectFile.count', 3, "Files not added" do 
        post :create, project: {
          name: "my project",
          files: [fixture_file_upload("files/windows.zip", "application/zip")]
        }
        assert_redirected_to projects_url, "Not directed to projects listing"
      end
    end
  end


  test "project create with multiple zip/plain text files should work" do
    log_in_as @user
    assert_difference 'Project.count', 1, "Project not added" do 
      assert_difference 'ProjectFile.count', 4, "Files not added" do 
        post :create, project: {
          name: "my project",
          files: [
            fixture_file_upload("files/windows.zip", "application/zip"),
            fixture_file_upload("files/data-ascii.dat", "text/plain"),
          ]
        }
        assert_redirected_to projects_url, "Not directed to projects listing"
      end
    end
  end


  test "should be able to batch create projects with zip" do
    log_in_as @user
    assert_difference 'Project.count', 2, "Project not added" do 
      assert_difference 'ProjectFile.count', 7, "Files not added" do
        post :create, project: {
          files: [fixture_file_upload("files/batch.zip", "application/zip")],
          batch: true
        }
        assert_redirected_to projects_url, "Not directed to projects listing"
      end
    end
  end

  test "should return error message on batch create with no files" do
    log_in_as @user
    assert_no_difference 'Project.count', "Project not added." do 
      assert_no_difference 'ProjectFile.count', "Files not added." do 
        post :create, project: {
          batch: true
        }
        assert_redirected_to projects_url, "Not directed to #{projects_url}"
        assert_not flash[:danger].empty?, "Error messages not present"
      end
    end
  end


  test "should be able to batch update projects with zip" do
    log_in_as @user
    assert_difference 'Project.count', 1, "Project not added" do 
      assert_difference 'ProjectFile.count', 6, "Files not added" do
        post :create, project: {
          files: [fixture_file_upload("files/batch.zip", "application/zip")],
          batch: true,
          update: true
        }
        assert_redirected_to projects_url, "Not directed to projects listing"
      end
    end
  end


  test "should be able to batch update projects with zip when not owner" do
    project = projects(:p1)
    ProjectPermission.create(project: project, user: users(:bar), can_view: true, 
      can_author: true, can_annotate: true)
    log_in_as users(:bar)
    assert_difference 'Project.count', 1, "Project not added" do 
      assert_difference 'ProjectFile.count', 6, "Files not added" do
        post :create, project: {
          files: [fixture_file_upload("files/batch.zip", "application/zip")],
          batch: true,
          update: true
        }
        assert_redirected_to projects_url, "Not directed to projects listing"
      end
    end
  end

  test "should only batch update projects with zip where user can author" do
    log_in_as users(:bar)
    assert_difference 'Project.count', 2, "Project not added" do 
      assert_difference 'ProjectFile.count', 7, "Files not added" do
        post :create, project: {
          files: [fixture_file_upload("files/batch.zip", "application/zip")],
          batch: true,
          update: true
        }
        assert_redirected_to projects_url, "Not directed to projects listing"
      end
    end
  end

end
