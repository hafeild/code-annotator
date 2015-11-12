require 'test_helper'

class Api::CommentsControllerTest < ActionController::TestCase
  
  def setup
    @user = users(:foo)
  end


  ## CREATE

  test "should fail and return error message when not logged in" do
    project = projects(:p1)
    assert_no_difference 'Comment.count', "Comment added." do 
      response = post :create, project_id: project.id, 
        comment: {content: "Blah blah blah"}
      message = JSON.parse(response.body)
      assert message['error'] == "You are not logged in."
    end
  end

  test "should fail and return error message with bad permissions on create" do
    log_in_as @user
    project = projects(:p2)
    assert_no_difference 'Comment.count', "Comment added." do 
      response = post :create, project_id: project.id, 
        comment: {content: "Blah blah blah"}
      message = JSON.parse(response.body)
      assert message['error'] == "Resource not available."
    end
  end

  test "should create comment and return success message with id on create" do
    log_in_as @user
    project = projects(:p1)
    assert_difference 'Comment.count', 1, "Comment not added." do 
      response = post :create, project_id: project.id, 
        comment: {content: "Blah blah blah"}
      message = JSON.parse(response.body)
      assert message['success'], "Response not successful: #{response.body}"
      assert message['id'] == Comment.last.id, 
        "Comment id doesn't match response."
      assert Comment.last.content == "Blah blah blah", 
        "Comment content doesn't match."
    end
  end



  ## INDEX

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



  ## SHOW

  test "should return comment on show" do
    log_in_as @user
    comment = comments(:comment1)

    response = get :show, id: comment.id
    response_comment = JSON.parse(response.body)['comment']
    assert_not response_comment.nil?, "No response."

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

  test "should return error message on show when not logged in" do
    comment = comments(:comment1)
    response = get :show, id: comment.id
    assert JSON.parse(response.body)['error'] == "You are not logged in."
  end

  test "should return error message on unauthorized show" do
    log_in_as @user
    comment = comments(:comment2)
    response = get :show, id: comment.id
    assert JSON.parse(response.body)['error'] == "Resource not available."
  end



  ## UPDATE

  test "should update comment and return success message on update" do
    log_in_as @user
    comment = comments(:comment1)
    response = patch :update, id: comment.id, comment: {content: "New content"}
    message = JSON.parse(response.body)
    assert message['success'], "Response not successful: #{response.body}"
    assert Comment.find(comment.id).content == "New content",
      "Comment content not updated."
  end

  test "should return error message on update when not logged in" do
    comment = comments(:comment1)
    response = patch :update, id: comment.id, comment: {content: "New content"}
    message = JSON.parse(response.body)
    assert message['error'] == "You are not logged in.", "Error not reported"
  end

  test "should return error message on unauthorized update" do
    log_in_as @user
    comment = comments(:comment2)
    response = patch :update, id: comment.id, comment: {content: "New content"}
    message = JSON.parse(response.body)
    assert message['error'] == "Resource not available.", "Error not reported"
  end  



  ## DESTROY

  test "should return success message on delete" do
    log_in_as @user
    response = delete :destroy, id: 1
    assert JSON.parse(response.body)['success']
  end
end
