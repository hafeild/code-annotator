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

  test "should perform updates on update" do
    log_in_as @user
    altcode = alternative_codes(:altcode1)
    updates = {
      content: "new content",
      start_line: 10,
      start_column: 0,
      end_line: 15,
      end_column: 70
    }
    response = patch :update, id: altcode.id, altcode: updates
    assert JSON.parse(response.body)['success']
    new_altcode = AlternativeCode.find_by(id: altcode.id)
    assert new_altcode.content == updates[:content]
    assert new_altcode.start_line == updates[:start_line]
    assert new_altcode.start_column == updates[:start_column]
    assert new_altcode.end_line == updates[:end_line]
    assert new_altcode.end_column == updates[:end_column]
  end

  test "should return an error on unauthorized update" do
    log_in_as @user
    altcode = alternative_codes(:altcode2)
    updates = {
      content: "new content",
      start_line: 10,
      start_column: 0,
      end_line: 15,
      end_column: 70
    }
    response = patch :update, id: altcode.id, altcode: updates
    assert JSON.parse(response.body)['error']
    new_altcode = AlternativeCode.find_by(id: altcode.id)
    assert_not new_altcode.content == updates[:content]
    assert_not new_altcode.start_line == updates[:start_line]
    assert_not new_altcode.start_column == updates[:start_column]
    assert_not new_altcode.end_line == updates[:end_line]
    assert_not new_altcode.end_column == updates[:end_column]
  end


  test "should return success message on delete" do
    log_in_as @user
    response = delete :destroy, id: 1
    assert JSON.parse(response.body)['success']
  end
end
