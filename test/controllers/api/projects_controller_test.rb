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

  test "should return success message on delete" do
    log_in_as @user
    response = delete :destroy, id: 1
    assert JSON.parse(response.body)['success']
  end
end
