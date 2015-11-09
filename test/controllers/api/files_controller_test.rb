require 'test_helper'

class Api::FilesControllerTest < ActionController::TestCase
  
  def setup
    @user = users(:foo)
  end

  test "should return success message on create" do
    log_in_as @user
    response = post :create, project_id: 1, file: {}
    assert JSON.parse(response.body)['success']
  end

  test "should return success message on index" do
    log_in_as @user
    response = get :index, project_id: 1
    assert JSON.parse(response.body)['success']
  end

  test "should return success message on download" do
    log_in_as @user
    response = get :download, project_id: 1
    assert JSON.parse(response.body)['success']
  end

  test "should return success message on print" do
    log_in_as @user
    response = get :print, project_id: 1
    assert JSON.parse(response.body)['success']
  end


  test "should return error message on show when not logged in" do
    file = project_files(:file1)
    response = get :show, id: file.id
    assert JSON.parse(response.body)['error'] == "You are not logged in."
  end

  test "should return error message on unauthorized show" do
    log_in_as @user
    file = project_files(:file2)
    response = get :show, id: file.id
    assert JSON.parse(response.body)['error'] == "Resource not available."
  end

  test "should return success message on show" do
    log_in_as @user
    file = project_files(:file1)
    response = get :show, id: file.id
    response_file = JSON.parse(response.body)['file']
    assert_not response_file.nil?, "No response."

    assert response_file['id'] == file.id, "Incorrect ID."
    assert response_file['content'] == file.content, "Incorrect content."
    assert response_file['name'] == file.name, "Incorrect name."

    ## Test presence of comment.
    comment = comments(:comment1)
    assert response_file['comments'].size == 1, "Incorrect number of comments."
    response_comment = response_file['comments'][0]

    assert response_comment['id'] == comment.id, "Incorrect comment id."
    assert response_comment['content'] == comment.content, 
      "Incorrect comment content."

    ## Test presence of comment location.
    comment_location = comment_locations(:cl1)
    assert response_comment['locations'].size == 1, 
      "Incorrect number of locations."
    response_comment_location = response_comment['locations'][0]

    assert response_comment_location['id'] == 
      comment_location.id, "Incorrect comment location"
    assert response_comment_location['file_id'] == 
      comment_location.project_file_id, "Incorrect file id."
    assert response_comment_location['start_line'] == 
      comment_location.start_line, "Incorrect start line."
    assert response_comment_location['start_column'] == 
      comment_location.start_column, "Incorrect start column."
    assert response_comment_location['end_line'] == 
      comment_location.end_line, "Incorrect end line."
    assert response_comment_location['end_column'] == 
      comment_location.end_column, "Incorrect end column."
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
