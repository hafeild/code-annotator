require 'test_helper'

class Api::PermissionsControllerTest < ActionController::TestCase
  
  def setup
    @user = users(:foo)
  end

  test "should add permission on create and return it" do
    log_in_as @user

    response = post :create, params: { 
      project_id: projects(:p1), permissions: {
        user_email: users(:bar).email, 
        can_view: true,
        can_author: false
      }
    }
    assert_not JSON.parse(response.body)['error'], "Error was returned."
    pp = ProjectPermission.find_by(user_id: users(:bar).id, 
      project_id: projects(:p1).id)
    assert pp, "Permission not found."
    assert pp.user_email.nil?, "Email not nil."
    assert pp.can_view, "can_view set to false."
    assert_not pp.can_author, "can_author set to true."
    assert_not pp.can_annotate, "can_annotate set to true."
    assert pp.project_id == projects(:p1).id, "Project ids don't match."
  end





  test "should return all permissions on index" do
    log_in_as @user
    pp_expected = project_permissions(:pp1)
    response = get :index, params: { project_id: projects(:p1) }
    json_response = JSON.parse(response.body)
    assert json_response.key?('permissions'), "No permissions returned."
    assert json_response['permissions'].size == 1, 
      "Didn't respond with expected number of permissions."
    pp = json_response['permissions'][0]
    assert pp['id'] == pp_expected.id, "Ids don't match up."
    assert pp['project_id'] == pp_expected.project_id, 
      "Project ids don't match."
    assert pp['user_email'] == pp_expected.user.email, 
      "User emails don't match."
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
    response = get :index, params: { project_id: projects(:p1) }
    assert JSON.parse(response.body)['error']
  end

  test "should return permissions on show" do
    log_in_as @user
    pp_expected = project_permissions(:pp1)
    response = get :show, params: { id: pp_expected }
    json_response = JSON.parse(response.body)
    assert json_response.key?('permissions'), "No permissions returned."
    pp = json_response['permissions']
    assert pp['id'] == pp_expected.id, "Ids don't match up."
    assert pp['project_id'] == pp_expected.project_id, 
      "Project ids don't match."
    assert pp['user_email'] == pp_expected.user.email, 
      "User emails don't match."
    assert pp['can_view'] == pp_expected.can_view, 
      "Viewing permissions don't match."
    assert pp['can_author'] == pp_expected.can_author, 
      "Authoring permissions don't match."
    assert pp['can_annotate'] == pp_expected.can_annotate, 
      "Annotation permissions don't match."
  end

  test "should return error on show without view permissions" do
    log_in_as users(:bar)
    pp_expected = project_permissions(:pp1)
    response = get :show, params: { id: pp_expected }
    json_response = JSON.parse(response.body)
    assert json_response['error']
    assert_not json_response.key?('permissions'), "No permissions returned."
  end


  test "should return success message on update" do
    log_in_as @user
    bar = users(:bar)
    pp = ProjectPermission.create(user: bar, project: projects(:p1),
      can_annotate: false, can_view: false, can_author: false)
    response = patch :update, params: { id: pp, permissions: {can_view: true} }
    assert_not JSON.parse(response.body)['error'], "Error returned."
    assert ProjectPermission.find(pp.id).can_view, 
      "Permission doesn't include can_view."
    assert_not ProjectPermission.find(pp.id).can_author, 
      "Permission includes can_author."
    assert_not ProjectPermission.find(pp.id).can_annotate, 
      "Permission includes can_annotate."
  end

  test "should return error message on update of user's permissions" do
    log_in_as @user
    pp = project_permissions(:pp1)
    response = patch :update, params: { 
      id: pp, permissions: {can_view: true} 
    }
    assert JSON.parse(response.body)['error'], "No error returned."
    assert ProjectPermission.find(pp.id).can_view, "can_view changed."
    assert ProjectPermission.find(pp.id).can_author, "can_author changed."
    assert ProjectPermission.find(pp.id).can_annotate, "can_annotate changed."
  end


  test "should return error message on removing viewing permissions from "+
      "author or annotator" do
    log_in_as @user
    bar = users(:bar)
    pp = ProjectPermission.create(user: bar, project: projects(:p1),
      can_annotate: true, can_view: true, can_author: true)
    response = patch :update, params: { id: pp, permissions: {can_view: false} }
    assert JSON.parse(response.body)['error'], "No error returned: #{response.body}"
    assert ProjectPermission.find(pp.id).can_view, 
      "Permission doesn't include can_view. #{response.body}"
    assert ProjectPermission.find(pp.id).can_author, 
      "Permission includes can_author."
    assert ProjectPermission.find(pp.id).can_annotate, 
      "Permission includes can_annotate."
  end

  test "should change viewing and annotation permissions when given a user "+
      "authoring permissions" do
    log_in_as @user
    bar = users(:bar)
    pp = ProjectPermission.create(user: bar, project: projects(:p1),
      can_annotate: false, can_view: false, can_author: false)
    response = patch :update, params: { id: pp, permissions: {can_author: true}}
    assert_not JSON.parse(response.body)['error'], "Error returned: "+
      "#{JSON.parse(response.body)['error']}."
    assert ProjectPermission.find(pp.id).can_view, 
      "Permission doesn't include can_view."
    assert ProjectPermission.find(pp.id).can_author, 
      "Permission includes can_author."
    assert ProjectPermission.find(pp.id).can_annotate, 
      "Permission includes can_annotate."
  end

  test "should return success message on delete" do
    log_in_as @user
    pp = project_permissions(:pp1)
    assert_difference 'ProjectPermission.count',-1, "Permissions not removed" do
      response = delete :destroy, params: { id: pp }
      assert JSON.parse(response.body)['success'], "Success not returned."
      assert ProjectPermission.find_by(id: pp.id).nil?, "Project not deleted."
    end
  end

  test "should return error message on delete without author permissions" do
    log_in_as users(:bar)
    pp = project_permissions(:pp1)
    assert_no_difference 'ProjectPermission.count', "Permissions not removed" do
      response = delete :destroy, params: { id: pp }
      assert JSON.parse(response.body)['error'], "No error returned."
      assert_not JSON.parse(response.body)['success'], "Returned success"
      assert_not ProjectPermission.find_by(id: pp.id).nil?, "Project deleted."
    end
  end
end
