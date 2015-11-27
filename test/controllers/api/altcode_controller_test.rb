require 'test_helper'

class Api::AltcodeControllerTest < ActionController::TestCase

  def setup
    @user = users(:foo)
  end

  test "should return success message on create" do
    log_in_as @user
    altcode = {
      content: "new content",
      start_line: 10,
      start_column: 0,
      end_line: 15,
      end_column: 70,
      file_id: project_files(:file1)
    }
    assert_difference "AlternativeCode.count", 1, "No new entry created" do
      response = post :create, project_id: projects(:p1), altcode: altcode
      assert JSON.parse(response.body)['success'], "Success message not returned."
      new_altcode = AlternativeCode.last
      assert JSON.parse(response.body)['id'] == new_altcode.id, "Ids don't match."
      assert new_altcode.created_by == @user.id, "Creators don't match."
      assert new_altcode.project_file == project_files(:file1), 
        "Files don't match."
      assert new_altcode.content == altcode[:content], "Content doesn't match."
      assert new_altcode.start_line == altcode[:start_line], 
        "start_line doesn't match."
      assert new_altcode.start_column == altcode[:start_column],
        "start_column doesn't match."
      assert new_altcode.end_line == altcode[:end_line],
        "end_line doesn't match."
      assert new_altcode.end_column == altcode[:end_column],
        "end_column doesn't match"
    end
  end


  test "should return error message on unauthorized create" do
    log_in_as @user
    altcode = {
      content: "new content",
      start_line: 10,
      start_column: 0,
      end_line: 15,
      end_column: 70,
      file_id: project_files(:file2)
    }

    assert_no_difference "AlternativeCode.count", "New entry created" do
      response = post :create, project_id: projects(:p2), altcode: altcode
      assert JSON.parse(response.body)['error'], "Error message not returned."
    end
    
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

  test "should return altcode message on show" do
    log_in_as @user
    exp_altcode = alternative_codes(:altcode1)
    response = get :show, id: exp_altcode

    response_json = JSON.parse(response.body)

    assert_not response_json['error'], "Error returned"

    assert response_json['altcode'], "No altcode."
    ret_altcode = response_json['altcode']
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

  test "should return error message on unauthorized show" do
    log_in_as @user
    exp_altcode = alternative_codes(:altcode2)
    response = get :show, id: exp_altcode
    response_json = JSON.parse(response.body)
    assert response_json['error'], "No error returned"
    assert_not response_json['altcode'], "Altcode returned."
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
    assert JSON.parse(response.body)['success'], "Success not returned."
    new_altcode = AlternativeCode.find_by(id: altcode.id)
    assert new_altcode.content == updates[:content], "Content doesn't match."
    assert new_altcode.start_line == updates[:start_line], 
      "start_line doesn't match."
    assert new_altcode.start_column == updates[:start_column],
      "start_column doesn't match."
    assert new_altcode.end_line == updates[:end_line],
      "end_line doesn't match."
    assert new_altcode.end_column == updates[:end_column],
      "end_column doesn't match."
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
    assert JSON.parse(response.body)['error'], "Error not returned."
    new_altcode = AlternativeCode.find_by(id: altcode.id)
    assert_not new_altcode.content == updates[:content], "Content updated."
    assert_not new_altcode.start_line == updates[:start_line],
      "start_line updated."
    assert_not new_altcode.start_column == updates[:start_column],
      "start_column updated."
    assert_not new_altcode.end_line == updates[:end_line],
      "end_line updated."
    assert_not new_altcode.end_column == updates[:end_column],
      "end_column updated."
  end


  test "should return success message on delete" do
    log_in_as @user
    response = delete :destroy, id: 1
    assert JSON.parse(response.body)['success']
  end
end
