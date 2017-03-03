require 'test_helper'

class Api::TagsControllerTest < ActionController::TestCase

  def setup
    @userFoo = users(:foo)
    @userBar = users(:bar)
    @fooP1 = projects(:p1)
    @fooP2 = projects(:p3)
    @barP1 = projects(:p2)
    @fooTag1 = tags(:tag1)
    @fooTag2 = tags(:tag2)
    @barTag1 = tags(:tag3)
  end

  ## Only logged in users should be able to perform any operation within this 
  ## controller.
  test "a logged out user cannot access any controllers" do
    ## Index:
    response = get :index
    assert JSON.parse(response.body)['error'], 
      "Error message not returned: #{response.body}"

    ## Show:
    response = get :show, id: @fooTag1.id
    assert JSON.parse(response.body)['error'], 
      "Error message not returned: #{response.body}"

    ## Create:
    assert_no_difference 'Tag.count', "Tag created" do
      response = post :create, tag: {text: "hello"}
      assert JSON.parse(response.body)['error'], 
        "Error message not returned: #{response.body}"
    end

    ## Update:
    response = patch :update, id: @fooTag1.id, tag: {text: "hello"}
    assert JSON.parse(response.body)['error'], 
      "Error message not returned: #{response.body}"

    ## Destroy:
    assert_no_difference 'Tag.count', "Tag destroyed" do
      response = delete :destroy, id: @fooTag1.id
      assert JSON.parse(response.body)['error'], 
        "Error message not returned: #{response.body}"
    end
  end

  test "a user cannot access any controllers for another user's tag" do
    log_in_as @userBar

    ## Show:
    response = get :show, id: @fooTag1.id
    assert JSON.parse(response.body)['error'], 
      "Error message not returned: #{response.body}"

    ## Update:
    response = patch :update, id: @fooTag1.id, tag: {text: "hello"}
    assert JSON.parse(response.body)['error'], 
      "Error message not returned: #{response.body}"

    ## Destroy:
    assert_no_difference 'Tag.count', "Tag destroyed" do
      response = delete :destroy, id: @fooTag1.id
      assert JSON.parse(response.body)['error'], 
        "Error message not returned: #{response.body}"
    end
  end

  test "a user can access all controllers for their tags" do
    log_in_as @userFoo

    ## Index:
    response = get :index
    assert_not JSON.parse(response.body)['error'], 
      "Error message returned: #{response.body}"

    ## Show:
    response = get :show, id: @fooTag1.id
    assert_not JSON.parse(response.body)['error'], 
      "Error message returned: #{response.body}"

    ## Create:
    assert_difference 'Tag.count', 1, "Tag not created" do
      response = post :create, tag: {text: "hello there"}
      assert_not JSON.parse(response.body)['error'], 
        "Error message returned: #{response.body}"
    end

    ## Update:
    response = patch :update, id: @fooTag1.id, tag: {text: "ack"}
    assert_not JSON.parse(response.body)['error'], 
      "Error message returned: #{response.body}"

    ## Destroy:
    assert_difference 'Tag.count', -1, "Tag not destroyed" do
      response = delete :destroy, id: @fooTag1.id
      assert_not JSON.parse(response.body)['error'], 
        "Error message returned: #{response.body}"
    end
  end

  ## Test index controller.
  test "index should return a list of all tags for a user" do
    log_in_as @userFoo

    response = get :index
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

  ## Test show controller.
  test "show should return the information for the given tag" do
    log_in_as @userFoo

    response = get :show, id: @fooTag1.id
    tag1 = JSON.parse(response.body)['tag']
    assert_not tag1.nil?, "Bad response: #{response.body}"

    ## First tag.
    assert (
      tag1['id'] == @fooTag1.id and 
      tag1['text'] == @fooTag1.text and 
      tag1['projects'].size == 1 and
      tag1['projects'][0]['id'] == @fooP1.id),
        "Returned values are incorrect: #{response.body}"
  end

  ## Test create controller.
  test "create should generate a new tag associated with the given project" do
    log_in_as @userFoo

    assert_difference 'Tag.count', 1, "Tag not created" do
      response = post :create, tag: {text: "hello there"}
      tag = JSON.parse(response.body)['tag']
      assert_not tag.nil?, "Bad response: #{response.body}"

      new_tag = Tag.last

      assert (new_tag.text == "hello there" and new_tag.projects.size == 0),
        "Stored values are incorrect: #{new_tag}"

      assert (
        tag['id'] == new_tag.id and 
        tag['text'] == "hello there" and
        tag['projects'].size == new_tag.projects.size),
        "Returned values are incorrect: #{response.body}"

    end
  end

  test "create should only accept a text parameter" do
    log_in_as @userFoo

    assert_no_difference 'Tag.count', "Tag created" do
      response = get :create, tag: {text: "hi", projects: ["x", "y"]}
      assert JSON.parse(response.body)['error'], 
        "Error message not returned: #{response.body}"
    end
  end


  test "create must include a text parameter" do
    log_in_as @userFoo

    assert_no_difference 'Tag.count', "Tag created" do
      response = get :create, tag: {}
      assert JSON.parse(response.body)['error'], 
        "Error message not returned: #{response.body}"
    end
  end

  ## Test update controller.
  test "update should modify the text of a tag" do 
    log_in_as @userFoo

    response = patch :update, id: @fooTag1.id, tag: {text: "A new name"}
    tag = JSON.parse(response.body)['tag']
    assert_not tag.nil?, "Bad response: #{response.body}"

    tag = Tag.find_by({id: @fooTag1.id})
    assert tag.text == "A new name", "Name not changed."
  end

  test "update should require exactly one param (text)" do 
    log_in_as @userFoo

    response = patch :update, id: @fooTag1.id, tag: {}
    assert JSON.parse(response.body)['error'], 
      "Error not returned with no params: #{response.body}"

    response = patch :update, id: @fooTag1.id, 
        tag: {text: "hi", user_id: @userFoo.id}
    assert JSON.parse(response.body)['error'], 
      "Error not returned with extra params: #{response.body}"
  end

  ## Test destroy controller.
  test "destroy should remove the given tag from the database" do
    log_in_as @userFoo

    assert_difference 'Tag.count', -1, "Tag not destroyed" do
      response = delete :destroy, id: @fooTag1.id
      assert_not JSON.parse(response.body)['error'], 
        "Error message returned: #{response.body}"

      assert Tag.find_by({id: @fooTag1.id}).nil?
    end
  end

end
