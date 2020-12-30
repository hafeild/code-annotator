require 'test_helper'
require 'set'

class Api::ProjectsControllerTest < ActionController::TestCase
  def setup
    @user = users(:foo)
    @project = @user.projects.first
  end

  test "should return success message on create" do
    log_in_as @user

    assert_difference 'Project.count', 1, "Project not added." do 
      assert_difference 'ProjectPermission.count', 1,"Permissions not added." do
        response = post :create, params: { project: {name: "my project"} }
        json_response = JSON.parse(response.body)
        assert json_response['success'], 
          "Response unsuccessful: #{response.body}"

        added_project = json_response['projects'][0]

        assert added_project['id'] == Project.last.id, 
          "Project id doesn't match."
        assert added_project['name'] == Project.last.name, 
          "Project name doesn't match."
        assert added_project['creator_email'] == Project.last.creator.email, 
          "Project email doesn't match."
        assert added_project['created_on'] == 
          Project.last.created_at.strftime("%d-%b-%Y"), 
          "Project name doesn't match."
        permission = ProjectPermission.find_by(project_id: Project.last.id)
        assert_not permission.nil?
        # assert permissions.size == 1, "No permission created."
        assert permission.user_id == @user.id, "User ids don't match."
        assert permission.can_view, "User cannot view."
        assert permission.can_author, "User cannot author."
        assert permission.can_annotate, "User cannot annotate."
        assert_not ProjectFile.find_by(project_id: Project.last.id, 
          directory_id: nil).nil?
      end
    end
  end

  test "should return success message on project create with zip file" do
    log_in_as @user
    assert_difference 'Project.count', 1, "Project not added." do 
      assert_difference 'ProjectFile.count', 3, "Files not added." do 
        response = post :create, params: { 
          project: {
            name: "my project",
            files: [fixture_file_upload("windows.zip", "application/zip")]
          }
        }
        json_response = JSON.parse(response.body)
        assert json_response['success'], 
          "Response unsuccessful. #{response.body}"

        added_project = json_response['projects'][0]

        assert added_project['id'] == Project.last.id, 
          "Project id doesn't match."
        assert added_project['name'] == Project.last.name, 
          "Project name doesn't match."
        assert added_project['creator_email'] == Project.last.creator.email, 
          "Project email doesn't match."
        assert added_project['created_on'] == 
          Project.last.created_at.strftime("%d-%b-%Y"), 
          "Project name doesn't match."
        permission = ProjectPermission.find_by(project_id: Project.last.id)
        assert_not permission.nil?
        assert permission.user_id == @user.id, "User ids don't match."
        assert permission.can_view, "User cannot view."
        assert permission.can_author, "User cannot author."
        assert permission.can_annotate, "User cannot annotate."
        assert_not ProjectFile.find_by(project_id: Project.last.id, 
          directory_id: nil).nil?
      end
    end
  end


  test "project create with multiple zip/plain text files should work" do
    log_in_as @user
    assert_difference 'Project.count', 1, "Project not added." do 
      assert_difference 'ProjectFile.count', 4, "Files not added." do 
        response = post :create, params: { 
          project: {
            name: "my project",
            files: [
              fixture_file_upload("windows.zip", "application/zip"),
              fixture_file_upload("data-ascii.dat", "text/plain"),
            ]
          }
        }
        json_response = JSON.parse(response.body)
        assert json_response['success'], 
          "Response unsuccessful. #{response.body}"

        added_project = json_response['projects'][0]
        assert added_project['id'] == Project.last.id, 
          "Project id doesn't match."
        assert added_project['name'] == Project.last.name, 
          "Project name doesn't match."
        assert added_project['creator_email'] == Project.last.creator.email, 
          "Project email doesn't match."
        assert added_project['created_on'] == 
          Project.last.created_at.strftime("%d-%b-%Y"), 
          "Project name doesn't match."
        permission = ProjectPermission.find_by(project_id: Project.last.id)
        assert_not permission.nil?
        assert permission.user_id == @user.id, "User ids don't match."
        assert permission.can_view, "User cannot view."
        assert permission.can_author, "User cannot author."
        assert permission.can_annotate, "User cannot annotate."
        assert_not ProjectFile.find_by(project_id: Project.last.id, 
          directory_id: nil).nil?
      end
    end
  end


  test "should be able to batch create projects with zip" do
    log_in_as @user
    assert_difference 'Project.count', 2, "Project not added" do 
      assert_difference 'ProjectFile.count', 7, "Files not added" do
        response = post :create, params: { 
          project: {
            files: [fixture_file_upload("batch.zip", "application/zip")],
            batch: true
          }
        }
        json_response = JSON.parse(response.body)
        assert json_response['success'], 
          "Response unsuccessful. #{response.body}"

      end
    end
  end

  test "should return error message on batch create with no files" do
    log_in_as @user
    assert_no_difference 'Project.count', "Project not added." do 
      assert_no_difference 'ProjectFile.count', "Files not added." do 
        response = post :create, params: { 
          project: {
            batch: true
          }
        }
        json_response = JSON.parse(response.body)
        assert_not json_response['success'], 
          "Response successful. #{response.body}"

      end
    end
  end


  test "should return error message on create with no name" do
    log_in_as @user

    assert_no_difference 'Project.count', "Project added." do 
      assert_no_difference 'ProjectPermission.count',"Permissions added." do
        response = post :create, params: { project: {} }
        json_response = JSON.parse(response.body)
        assert json_response['error'], 'Response successful.'
      end
    end
  end


  test "should be able to batch update projects with zip" do
    log_in_as @user
    assert_difference 'Project.count', 1, "Project not added" do 
      assert_difference 'ProjectFile.count', 6, "Files not added" do
        response = post :create, params: { 
          project: {
            files: [fixture_file_upload("batch.zip", "application/zip")],
            batch: true,
            update: true
          }
        }
        json_response = JSON.parse(response.body)
        assert json_response['success'], 
          "Response unsuccessful. #{response.body}"

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
        response = post :create, params: { 
          project: {
            files: [fixture_file_upload("batch.zip", "application/zip")],
            batch: true,
            update: true
          }
        }
        json_response = JSON.parse(response.body)
        assert json_response['success'], 
          "Response unsuccessful. #{response.body}"

      end
    end
  end

  test "should only batch update projects with zip when user can author" do
    log_in_as users(:bar)
    assert_difference 'Project.count', 2, "Project not added" do 
      assert_difference 'ProjectFile.count', 7, "Files not added" do
        response = post :create, params: { 
          project: {
            files: [fixture_file_upload("batch.zip", "application/zip")],
            batch: true,
            update: true
          }
        }
        json_response = JSON.parse(response.body)
        assert json_response['success'], 
          "Response unsuccessful. #{response.body}"

      end
    end
  end



  test "should return list of projects on index when logged in" do
    log_in_as @user
    response = get :index
    @projects = JSON.parse(response.body)['projects']
    assert @projects 

    matches = 0;
    expectedProjects = Set.new(
      @user.project_permissions.where({can_view: true}).map{|x| x.project.id})
    ## Make sure the user is authorized to view all the projects listed.
    @projects.each do |p|
      assert expectedProjects.member?(p['id']), "Unauthorized project."
      matches += 1
    end
    ## Make sure all the projects the user is authorized to view are listed.
    assert matches == expectedProjects.size, "Not all projects listed."
  end

  test "should return error message on index when not logged in" do
    response = get :index
    assert JSON.parse(response.body)['error'] == "You are not logged in."
  end

  test "should return success message on show" do
    log_in_as @user
    response = get :show, params: { id: 1 }
    assert JSON.parse(response.body)['success']
  end

  test "should return error message on update without name" do
    log_in_as @user
    response = patch :update, params: { id: 1 }
    assert JSON.parse(response.body)['error']
  end

  test "should update project name" do
    log_in_as @user
    new_name = "A very new name"
    response = patch :update, params: { 
      id: @project.id, project: {name: new_name}
    }
    assert JSON.parse(response.body)['success'], "Response not successful"
    assert Project.find(@project.id).name == new_name, "Name not changed in db."
  end

  test "should return success message on delete and remove everything "+
      "connected with the project" do
    log_in_as @user
    project = projects(:p1)
    pp_id = project_permissions(:pp1).id
    file_id = project_files(:file1).id
    comment_id = comments(:comment1).id
    cl_id = comment_locations(:cl1).id
    altcode_id = alternative_codes(:altcode1).id

    response = delete :destroy, params: { id: project.id }
    response = JSON.parse(response.body)
    assert response['success']
    assert Project.find_by(id: project.id).nil?
    assert ProjectPermission.find_by(id: pp_id).nil?
    assert ProjectFile.find_by(id: file_id).nil?
    assert Comment.find_by(id: comment_id).nil?
    assert CommentLocation.find_by(id: cl_id).nil?
    assert AlternativeCode.find_by(id: altcode_id).nil?
  end


  test "should return error when delete on project without author permissions" do
    log_in_as users(:bar)

    project = projects(:p1)
    pp_id = project_permissions(:pp1).id
    file_id = project_files(:file1).id
    comment_id = comments(:comment1).id
    cl_id = comment_locations(:cl1).id
    altcode_id = alternative_codes(:altcode1).id

    response = delete :destroy, params: { id: project.id }
    response = JSON.parse(response.body)
    assert response['error']
    assert_not Project.find_by(id: project.id).nil?
    assert_not ProjectPermission.find_by(id: pp_id).nil?
    assert_not ProjectFile.find_by(id: file_id).nil?
    assert_not Comment.find_by(id: comment_id).nil?
    assert_not CommentLocation.find_by(id: cl_id).nil?
    assert_not AlternativeCode.find_by(id: altcode_id).nil?
  end
end
