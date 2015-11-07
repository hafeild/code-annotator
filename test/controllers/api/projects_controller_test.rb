require 'test_helper'
require 'set'

class Api::ProjectsControllerTest < ActionController::TestCase
  def setup
    @user = users(:foo)
    @project = @user.projects.first
  end

  test "should return success message on create" do
    log_in_as @user
    @response = post :create, project: {}
    assert JSON.parse(@response.body)['success']
  end

  test "should return list of projects on index when logged in" do
    log_in_as @user
    @response = get :index
    @projects = JSON.parse(@response.body)['projects']
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
    @response = get :index
    assert JSON.parse(@response.body)['error'] == "You are not logged in."
  end

  test "should return success message on show" do
    log_in_as @user
    @response = get :show, id: 1
    assert JSON.parse(@response.body)['success']
  end

  test "should return success message on update" do
    log_in_as @user
    @response = patch :update, id: 1
    assert JSON.parse(@response.body)['success']
  end

  test "should return success message on delete" do
    log_in_as @user
    @response = delete :destroy, id: 1
    assert JSON.parse(@response.body)['success']
  end
end
