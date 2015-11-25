require 'test_helper'

class Api::PermissionsControllerTest < ActionController::TestCase
  
  def setup
    @user = users(:foo)
  end

  test "should return success message on create" do
    log_in_as @user
    response = post :create, project_id: 1, permission: {}
    assert JSON.parse(response.body)['success']
  end

  test "should return all permissions on index" do
    log_in_as @user
    pp_expected = project_permissions(:pp1)
    response = get :index, project_id: projects(:p1)
    json_response = JSON.parse(response.body)
    assert json_response.key?('permissions'), "No permissions returned."
    assert json_response['permissions'].size == 1, 
      "Didn't respond with expected number of permissions."
    pp = json_response['permissions'][0]
    assert pp['id'] == pp_expected.id, "Ids don't match up."
    assert pp['project_id'] == pp_expected.project_id, 
      "Project ids don't match."
    assert pp['user_name'] == pp_expected.user.name, "User names don't match."
    assert pp['user_email'] == pp_expected.user.email, 
      "User emails don't match."
    assert pp['user_id'] == pp_expected.user.id, "User ids don't match."
    assert pp['can_view'] == pp_expected.can_view, 
      "Viewing permissions don't match."
    assert pp['can_author'] == pp_expected.can_author, 
      "Authoring permissions don't match."
    assert pp['can_annotate'] == pp_expected.can_annotate, 
      "Annotation permissions don't match."
  end

  test "should return error message on index without correct permissions" do
    log_in_as users(:bar)
    pp_expected = project_permissions(:pp1)
    response = get :index, project_id: projects(:p1)
    assert JSON.parse(response.body)['error']
  end

  test "should return permissions on show" do
    log_in_as @user
    pp_expected = project_permissions(:pp1)
    response = get :show, id: pp_expected
    json_response = JSON.parse(response.body)
    assert json_response.key?('permissions'), "No permissions returned."
    pp = json_response['permissions']
    assert pp['id'] == pp_expected.id, "Ids don't match up."
    assert pp['project_id'] == pp_expected.project_id, 
      "Project ids don't match."
    assert pp['user_name'] == pp_expected.user.name, "User names don't match."
    assert pp['user_email'] == pp_expected.user.email, 
      "User emails don't match."
    assert pp['user_id'] == pp_expected.user.id, "User ids don't match."
    assert pp['can_view'] == pp_expected.can_view, 
      "Viewing permissions don't match."
    assert pp['can_author'] == pp_expected.can_author, 
      "Authoring permissions don't match."
    assert pp['can_annotate'] == pp_expected.can_annotate, 
      "Annotation permissions don't match."
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
