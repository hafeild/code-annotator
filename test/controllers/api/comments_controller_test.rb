require 'test_helper'

class Api::CommentsControllerTest < ActionController::TestCase
  
  def setup
    @user = users(:foo)
  end

  test "should return success message on create" do
    log_in_as @user
    response = post :create, project_id: 1, comment: {}
    assert JSON.parse(response.body)['success']
  end

  test "should return correct messages on index by project" do
    log_in_as @user
    project = projects(:p1)
    response = get :index, project_id: project.id
    response_comments = JSON.parse(response.body)['comments']
    assert_not response_comments.nil?, "No response."

    assert response_comments.size == 1, "Incorrect number of comments."

    comment = comments(:comment1)
    response_comment = response_comments[0]

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

  test "should return correct messages on index by project and file" do
    log_in_as @user
    project = projects(:p1)
    file = project_files(:file1)
    response = get :index, project_id: project.id, file_id: file.id
    response_comments = JSON.parse(response.body)['comments']
    assert_not response_comments.nil?, "No response."

    assert response_comments.size == 1, "Incorrect number of comments."

    comment = comments(:comment1)
    response_comment = response_comments[0]

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


  test "should return error message on index when not logged in" do
    project = projects(:p1)
    response = get :index, project_id: project.id
    assert JSON.parse(response.body)['error'] == "You are not logged in."
  end

  test "should return error message on unauthorized index" do
    log_in_as @user
    project = projects(:p2)
    response = get :index, project_id: project.id
    assert JSON.parse(response.body)['error'] == "Resource not available."
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
