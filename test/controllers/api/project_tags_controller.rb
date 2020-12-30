require 'test_helper'

class Api::ProjectTagsControllerTest < ActionController::TestCase

  def setup
    @userFoo = users(:foo)
    @userBar = users(:bar)
    @fooP1 = projects(:p1)
    @fooP2 = projects(:p3)
    @barP1 = projects(:p2)
    @fooTag1 = tags(:tag1)
    @fooTag2 = tags(:tag2)
    @barTag1 = tags(:tag3)
    @fooP1Tag1 = project_tags(:ptag1)
    @fooP1Tag2 = project_tags(:ptag3)
    @fooP2Tag3 = project_tags(:ptag2)
  end

  ## Only logged in users should be able to perform any operation within this 
  ## controller.
  test "a logged out user cannot access any controllers" do
    ## Index:
    response = get :index, params: { project_id: @fooP1.id }
    assert JSON.parse(response.body)['error'], 
      "Error message not returned: #{response.body}"

    ## Create:
    assert_no_difference 'Tag.count', "Tag created" do
      response = post :create, params: { 
        project_id: @fooP2.id, tag_id: @fooTag1.id
      }
      assert JSON.parse(response.body)['error'], 
        "Error message not returned: #{response.body}"
    end

    ## Destroy:
    assert_no_difference 'Tag.count', "Tag destroyed" do
      response = delete :destroy, params: { 
        project_id: @fooP1.id, tag_id: @fooTag1.id
      }
      assert JSON.parse(response.body)['error'], 
        "Error message not returned: #{response.body}"
    end
  end

  test "a user cannot access any controllers for another user's tag" do
    log_in_as @userBar

    ## Create:
    assert_no_difference 'ProjectTag.count', "Tag created" do
      response = post :create, params: { 
        project_id: @fooP2.id, tag: {text: "hi"}
      }
      assert JSON.parse(response.body)['error'], 
        "Error message not returned: #{response.body}"
    end

    ## Destroy:
    assert_no_difference 'ProjectTag.count', "Tag destroyed" do
      response = delete :destroy, params: { project_id: @fooP1.id, tag_id: @fooTag1.id
      }
      assert JSON.parse(response.body)['error'], 
        "Error message not returned: #{response.body}"
    end
  end

  test "a user can access all controllers for their tags" do
    log_in_as @userFoo

    ## Index:
    response = get :index, params: { project_id: @fooP1.id }
    assert_not JSON.parse(response.body)['error'], 
      "Error message returned: #{response.body}"

    ## Create:
    assert_difference 'ProjectTag.count', 1, "Tag not created" do
      response = post :create, params: { 
        project_id: @fooP2.id, tag: {text: "hi"}
      }
      assert_not JSON.parse(response.body)['error'], 
        "Error message returned: #{response.body}"
    end

    ## Destroy:
    assert_difference 'ProjectTag.count', -1, "Tag not destroyed" do
      response = delete :destroy, params: { 
        project_id: @fooP1.id, tag_id: @fooTag1.id
      }
      assert_not JSON.parse(response.body)['error'], 
        "Error message returned: #{response.body}"
    end
  end

  ## Test index controller.
  test "index should return a list of all tags for a user's project" do
    log_in_as @userFoo

    response = get :index, params: { project_id: @fooP1.id }
    tags = JSON.parse(response.body)['tags']
    assert_not tags.nil?, "Bad response: #{response.body}"
    assert tags.size == 2, 
      "Incorrect number of tags returned: #{response.body}"

    if tags[0]['id'] == @fooTag1.id 
      (tag1, tag2) = tags
    else
      (tag2, tag1) = tags
    end

    ## First tag.
    assert (
      tag1['id'] == @fooTag1.id and 
      tag1['text'] == @fooTag1.text and 
      tag1['projects'].size == 1 and
      tag1['projects'][0]['id'] == @fooP1.id),
        "Values for entry one incorrect: #{response.body}"

    assert (
      tag2['id'] == @fooTag2.id and 
      tag2['text'] == @fooTag2.text and 
      tag2['projects'].size == 2 and
      tag2['projects'][0]['id'] == @fooP1.id || @fooP2.id and
      tag2['projects'][1]['id'] == @fooP1.id || @fooP2.id),
        "Values for entry one incorrect: #{response.body}"
  end

  ## Test create controller.
  test "create should generate a new tag associated with the given project" do
    log_in_as @userFoo

    assert_difference 'Tag.count', 1, "Tag not created" do
      assert_difference 'ProjectTag.count', 1, "Project tag not created" do
        response = post :create, params: { 
          project_id: @fooP1.id, tag: {text: "a"}
        } 
        tag = JSON.parse(response.body)['tag']
        assert_not tag.nil?, "Bad response: #{response.body}"
  
        new_tag = Tag.last
  
        assert (new_tag.text == "a" and new_tag.projects.size == 1),
          "Stored values are incorrect: #{new_tag}"
  
        new_project_tag = ProjectTag.last

        assert (new_project_tag.tag_id == new_tag.id), 
          "Stored project tag values are incorrect: #{new_project_tag}"

        assert (
          tag['id'] == new_tag.id and 
          tag['text'] == new_tag.text and
          tag['projects'].size == new_tag.projects.size),
          "Returned values are incorrect: #{response.body}"

      end
    end
  end

  test "create should associated an existing tag with the given project" do
    log_in_as @userFoo

    assert_no_difference 'Tag.count', "Tag created" do
      assert_difference 'ProjectTag.count', 1, "Project tag not created" do
        response = post :create, params: { 
          project_id: @fooP2.id, tag_id: @fooTag1.id
        }
        tag = JSON.parse(response.body)['tag']
        assert_not tag.nil?, "Bad response: #{response.body}"
  
        new_project_tag = ProjectTag.last

        assert (new_project_tag.tag_id == tag['id']), 
          "Stored project tag values are incorrect: #{new_project_tag}"

        assert (
          tag['id'] == new_project_tag.tag.id and 
          tag['text'] == new_project_tag.tag.text and
          tag['projects'].size == new_project_tag.tag.projects.size),
          "Returned values are incorrect: #{response.body}"

      end
    end
  end


  test "create should only accept a text parameter" do
    log_in_as @userFoo

    assert_no_difference 'Tag.count', "Tag created" do
      response = get :create, params: { 
        project_id: @fooP1.id, 
        tag: {text: "hi", projects: ["x", "y"]}
      }
      assert JSON.parse(response.body)['error'], 
        "Error message not returned: #{response.body}"
    end
  end


  test "create must include a text parameter or tag id" do
    log_in_as @userFoo

    assert_no_difference 'Tag.count', "Tag created" do
      response = get :create, params: { project_id: @fooP1, tag: {} }
      assert JSON.parse(response.body)['error'], 
        "Error message not returned: #{response.body}"
    end
  end

  ## Test destroy controller.
  test "destroy should remove the given project tag from the database" do
    log_in_as @userFoo

    assert_difference 'ProjectTag.count', -1, "Project tag not destroyed" do
      response = delete :destroy, params: { 
        project_id: @fooP1.id, tag_id: @fooTag1.id
      }
      assert_not JSON.parse(response.body)['error'], 
        "Error message returned: #{response.body}"

      assert ProjectTag.find_by({tag_id: @fooTag1.id}).nil?
    end
  end

end
