require 'test_helper'

class Api::FilesControllerTest < ActionController::TestCase
  
  def setup
    @user = users(:foo)
  end

  ## Create a directory.

  test "should return success message on create_directory" do
    log_in_as @user
    project = projects(:p1)
    assert_difference "ProjectFile.count", 1, "Directory not added" do
      response = post :create_directory, project_id: project.id, directory: {
        directory_id: project_files(:file1Root).id, name: "My new dir"
      }
      json_response = JSON.parse(response.body)
      assert json_response['success'], "Success not returned."
      assert_not json_response['id'].nil?, "No id returned."
      directory = ProjectFile.find_by(id: json_response['id'])
      assert directory, "Invalid id returned."
      assert directory.is_directory, "is_directory not set correctly."
      assert directory.name == "My new dir", "name not set correctly."
      assert directory.directory_id == project_files(:file1Root).id, 
        "directory_id not set correctly."
      assert directory.size == 0, "size not set correctly."
      assert directory.added_by == @user.id, "added_by not set correctly."
      assert directory.project_id == project.id, "project_id not set correctly."
      assert directory.content == "", "content not set correctly."
    end
  end


  test "should return attach created directory to root when no dir_id given" do
    log_in_as @user
    project = projects(:p1)
    root = project_files(:file1Root)
    assert_difference "ProjectFile.count", 1, "Directory not added" do
      response = post :create_directory, project_id: project.id, directory: {
        name: "My new dir"
      }
      json_response = JSON.parse(response.body)
      assert json_response['success'], "Success not returned."
      assert_not json_response['id'].nil?, "No id returned."
      directory = ProjectFile.find_by(id: json_response['id'])
      assert directory, "Invalid id returned."
      assert directory.is_directory, "is_directory not set correctly."
      assert directory.name == "My new dir", "name not set correctly."
      assert directory.directory_id == root.id, 
        "directory_id not set correctly. #{directory.to_json} : #{root.to_json}"
      assert directory.size == 0, "size not set correctly."
      assert directory.added_by == @user.id, "added_by not set correctly."
      assert directory.project_id == project.id, "project_id not set correctly."
      assert directory.content == "", "content not set correctly."
    end
  end


  test "should return error message on unauthorized create_directory" do
    log_in_as users(:bar)
    project = projects(:p1)
    assert_no_difference "ProjectFile.count", "Directory added" do
      response = post :create_directory, project_id: project.id, directory: {
        directory_id: project_files(:file1Root).id, name: "My new dir"
      }
      json_response = JSON.parse(response.body)
      assert json_response['error'], "Error not returned."
    end
  end


  ## Index.

  test "should return success message on index" do
    log_in_as @user
    response = get :index, project_id: 1
    assert JSON.parse(response.body)['success']
  end


  ## Print.

  test "should return success message on print" do
    log_in_as @user
    response = get :print, project_id: 1
    assert JSON.parse(response.body)['success']
  end


  ## Show.

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

 test "should return success message on show_public with valid link" do
    log_in_as users(:bar)
    file = project_files(:file1)
    response = get :show_public, link_uuid: "alink", id: file.id
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

  test "should return error message on show with invalid public link" do
    log_in_as users(:bar)
    file = project_files(:file1)
    response = get :show_public, link_uuid: "abadlink", id: file.id
    assert JSON.parse(response.body)['error'] == "Resource not available."
  end



  ## Update

  test "should return success message on update" do
    log_in_as @user
    response = patch :update, id: 1
    assert JSON.parse(response.body)['success']
  end



  ## Destroy.

  test "should return return error on root delete"do
    log_in_as @user
    file_to_remove = project_files(:file1Root)

    commentloc = comment_locations(:cl1)
    altcode = alternative_codes(:altcode1)

    assert_no_difference 'ProjectFile.count', "Files removed." do
      response = delete :destroy, id: file_to_remove.id
      assert JSON.parse(response.body)['error'], "Error not returned."
    end
  end

  test "should return delete all sub files, locations, and altocde on dir delete"do
    log_in_as @user
    file_to_remove = project_files(:dir1)

    commentloc = comment_locations(:cl1)
    altcode = alternative_codes(:altcode1)

    assert_difference 'ProjectFile.count', -2, "Files not removed." do
      response = delete :destroy, id: file_to_remove.id
      assert JSON.parse(response.body)['success'], "Success not returned."

      ## Only root should be left.      
      assert ProjectFile.where(project_id: projects(:p1).id).size == 1, 
        "Files to delete not deleted."

      ## Make sure that all comment locations and altcode for this file have
      ## been removed.
      assert CommentLocation.find_by(id: commentloc.id).nil?,
        "CommentLocations not destroyed."
      assert AlternativeCode.find_by(id: altcode.id).nil?,
        "Altcode not destroyed."
    end
  end

  test "should delete file, locations, and altcode message on destroy" do
    log_in_as @user
    file_to_remove = project_files(:file1)

    commentloc = comment_locations(:cl1)
    altcode = alternative_codes(:altcode1)

    assert_difference 'ProjectFile.count', -1, "File not removed." do
      response = delete :destroy, id: file_to_remove.id
      assert JSON.parse(response.body)['success'], "Success not returned."
      assert ProjectFile.where(project_id: projects(:p1).id).size == 2, 
        "Files to delete not deleted."

      ## Make sure that all comment locations and altcode for this file have
      ## been removed.
      assert CommentLocation.find_by(id: commentloc.id).nil?,
        "CommentLocations not destroyed."
      assert AlternativeCode.find_by(id: altcode.id).nil?,
        "Altcode not destroyed."
    end
  end


  test "should return error message on destroy without permissions" do
    log_in_as @user
    file_to_remove = project_files(:dir2)

    commentloc = comment_locations(:cl2)
    altcode = alternative_codes(:altcode2)

    assert_no_difference 'ProjectFile.count', "Files removed." do
      response = delete :destroy, id: file_to_remove.id
      assert JSON.parse(response.body)['error'], "Error not returned."
      assert ProjectFile.where(project_id: projects(:p1).id).size == 3, 
        "Files deleted."

      ## Make sure that all comment locations and altcode for this file have
      ## been removed.
      assert_not CommentLocation.find_by(id: commentloc.id).nil?,
        "CommentLocations destroyed."
      assert_not AlternativeCode.find_by(id: altcode.id).nil?,
        "Altcode destroyed."
    end
  end
end
