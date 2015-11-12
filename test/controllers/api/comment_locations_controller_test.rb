require 'test_helper'

class Api::CommentLocationsControllerTest < ActionController::TestCase
  
  def setup
    @user = users(:foo)
  end

  test "should return error message on create with incorrect data" do
    log_in_as @user
    comment = comments(:comment1)
    response = post :create, comment_id: comment.id, comment_location: {
      project_file_id: project_files(:file2).id,
      start_line: 3,
      start_column: 0,
      end_line: 4,
      end_column: 80
    }
    assert JSON.parse(response.body)['error'] == 
      "Couldn't save comment; ensure all fields are valid.",
      "Expected error message not returned: #{response.body}"
  end

  test "should return error message on create with missing data" do
    log_in_as @user
    comment = comments(:comment1)
    response = post :create, comment_id: comment.id, comment_location: {}
    assert JSON.parse(response.body)['error'] == 
      "Not all required fields are present.",
      "Expected error message not returned: #{response.body}"
  end

  test "should return success message with id on create" do
    log_in_as @user
    comment = comments(:comment1)
    file = project_files(:file1)
    response = post :create, comment_id: comment.id, comment_location: {
      project_file_id: file.id,
      start_line: 3,
      start_column: 0,
      end_line: 4,
      end_column: 80
    }
    success_response = JSON.parse(response.body)

    assert success_response['success'], 
      "Creation not successful: #{response.body}"
    assert success_response['id'] == CommentLocation.last.id, 
      "Returned id doesn't match database."
  end



  test "should return success message on update" do
    log_in_as @user
    response = patch :update, comment_id: 1, location_id: 1
    assert JSON.parse(response.body)['success']
  end

  test "should return success message on destroy" do
    log_in_as @user
    response = delete :destroy, comment_id: 1, location_id: 1
    assert JSON.parse(response.body)['success']
  end

end