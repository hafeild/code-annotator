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
        response = post :create, project: {name: "my project"}
        json_reponse = JSON.parse(response.body)
        assert json_reponse['success'], 'Response unsuccessful.'
        assert json_reponse['id'] == Project.last.id, 
          "Project id doesn't match."
        assert json_reponse['name'] == Project.last.name, 
          "Project name doesn't match."
        assert json_reponse['creator_email'] == Project.last.creator.email, 
          "Project email doesn't match."
        assert json_reponse['created_on'] == 
          Project.last.created_at.strftime("%d-%b-%Y"), 
          "Project name doesn't match."
        permission = ProjectPermission.find_by(project_id: Project.last.id)
        assert_not permission.nil?
        # assert permissions.size == 1, "No permission created."
        assert permission.user_id == @user.id, "User ids don't match."
        assert permission.can_view, "User cannot view."
        assert permission.can_author, "User cannot author."
        assert permission.can_annotate, "User cannot annotate."
      end
    end
  end

  test "should return error message on create with no name" do
    log_in_as @user

    assert_no_difference 'Project.count', "Project added." do 
      assert_no_difference 'ProjectPermission.count',"Permissions added." do
        response = post :create, project: {}
        json_reponse = JSON.parse(response.body)
        assert json_reponse['error'], 'Response successful.'
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
    response = get :show, id: 1
    assert JSON.parse(response.body)['success']
  end

  test "should return success message on update" do
    log_in_as @user
    response = patch :update, id: 1
    assert JSON.parse(response.body)['success']
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

    response = delete :destroy, id: project.id
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

    response = delete :destroy, id: project.id
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
