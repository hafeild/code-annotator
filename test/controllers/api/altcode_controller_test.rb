require 'test_helper'

class Api::AltcodeControllerTest < ActionController::TestCase

  def setup
    @user = users(:foo)
  end

  test "should return success message on create" do
    log_in_as @user
    response = post :create, project_id: 1, altcode: {}
    assert JSON.parse(response.body)['success']
  end

  test "should return success message on index by project" do
    log_in_as @user
    exp_altcode = alternative_codes(:altcode1)
    response = get :index, project_id: projects(:p1)
    response_json = JSON.parse(response.body)
    assert_not response_json['error'], "Error returned"
    assert response_json['altcode'], "No altcode."
    assert response_json['altcode'].size == 1, 
      "Incorrect number of altcodes returned."
    ret_altcode = response_json['altcode'][0]
    assert ret_altcode['id'] == exp_altcode.id, "IDs don't match."
    assert ret_altcode['content'] == exp_altcode.content, 
      "Contents don't match."
    assert ret_altcode['file_id'] == exp_altcode.project_file.id, 
    "File ids don't match."
    assert ret_altcode['start_line'] == exp_altcode.start_line, 
      "start_lines don't match."
    assert ret_altcode['start_column'] == exp_altcode.start_column, 
      "start_columns don't match."
    assert ret_altcode['end_line'] == exp_altcode.end_line, 
      "end_lines don't match."
    assert ret_altcode['end_column'] == exp_altcode.end_column, 
      "end_column don't match."
    assert ret_altcode['creator_email'] == exp_altcode.creator.email, 
      "created_by don't match."
  end

  test "should return success message on index by file" do
    log_in_as @user
    exp_altcode = alternative_codes(:altcode1)
    response = get :index, project_id: projects(:p1), 
      file_id: project_files(:file1)
    response_json = JSON.parse(response.body)
    assert_not response_json['error'], "Error returned"
    assert response_json['altcode'], "No altcode."
    assert response_json['altcode'].size == 1, 
      "Incorrect number of altcodes returned."
    ret_altcode = response_json['altcode'][0]
    assert ret_altcode['id'] == exp_altcode.id, "IDs don't match."
    assert ret_altcode['content'] == exp_altcode.content, 
      "Contents don't match."
    assert ret_altcode['file_id'] == exp_altcode.project_file.id, 
    "File ids don't match."
    assert ret_altcode['start_line'] == exp_altcode.start_line, 
      "start_lines don't match."
    assert ret_altcode['start_column'] == exp_altcode.start_column, 
      "start_columns don't match."
    assert ret_altcode['end_line'] == exp_altcode.end_line, 
      "end_lines don't match."
    assert ret_altcode['end_column'] == exp_altcode.end_column, 
      "end_column don't match."
    assert ret_altcode['creator_email'] == exp_altcode.creator.email, 
      "created_by don't match."
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
