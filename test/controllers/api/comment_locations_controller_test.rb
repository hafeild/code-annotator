require 'test_helper'

class Api::CommentLocationsControllerTest < ActionController::TestCase
  
  def setup
    @user = users(:foo)
  end

  ## CREATE

  test "should return error message on create with incorrect data" do
    log_in_as @user
    comment = comments(:comment1)
    assert_no_difference 'CommentLocation.count', "CommentLocation added." do 
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
  end

  test "should return error message on create with missing data" do
    log_in_as @user
    comment = comments(:comment1)
    assert_no_difference 'CommentLocation.count', "CommentLocation added." do 
      response = post :create, comment_id: comment.id, comment_location: {}
      assert JSON.parse(response.body)['error'] == 
        "Not all required fields are present.",
        "Expected error message not returned: #{response.body}"
    end
  end

  test "should return success message with id on create" do
    log_in_as @user
    comment = comments(:comment1)
    file = project_files(:file1)
    assert_difference 'CommentLocation.count', 1, "No CommentLocation added." do 
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
  end



  ## DESTROY

  test "should return remove comment location and return success on destroy" do
    log_in_as @user
    comment_location = comment_locations(:cl1)
    assert_difference 'CommentLocation.count',-1,"No CommentLocation removed."do 
      response = delete :destroy, id: comment_location.id
      assert JSON.parse(response.body)['success'], 
        "Success message not returned: #{response.body}"
      assert CommentLocation.find_by(id: comment_location.id).nil?, 
        "Deleted comment still in database."
    end
  end

  test "should return error message on destroy when not logged in" do
    comment_location = comment_locations(:cl1)
    assert_no_difference 'CommentLocation.count', "CommentLocation removed." do 
      response = delete :destroy, id: comment_location.id
      assert JSON.parse(response.body)['error'] == "You are not logged in.",
        "Unexpected error message: #{response.body}"
    end
  end

  test "should return error message on destroy with bad permissions" do
    log_in_as @user
    comment_location = comment_locations(:cl2)
    assert_no_difference 'CommentLocation.count', "CommentLocation removed." do 
      response = delete :destroy, id: comment_location.id
      assert JSON.parse(response.body)['error'] == "Resource not available.",
        "Unexpected error message: #{response.body}"
    end
  end

end