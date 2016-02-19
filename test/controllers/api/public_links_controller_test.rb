require 'test_helper'

class Api::PublicLinksControllerTest < ActionController::TestCase

  def setup
    @user = users(:foo)
    @project = projects(:p1)
    @link1 = public_links(:pub_link1)
    @link2 = public_links(:pub_link2)
  end

  ## Only logged in users with author permissions should be able to perform
  ## any operation within this controller.
  test "a logged out user cannot access any controllers" do
    ## Index:
    response = get :index, project_id: @project.id
    assert JSON.parse(response.body)['error'], 
      "Error message not returned: #{response.body}"

    ## Show:
    response = get :show, id: @link1.id
    assert JSON.parse(response.body)['error'], 
      "Error message not returned: #{response.body}"

    ## Create:
    assert_no_difference 'PublicLink.count', "Link created" do
      response = get :create, project_id: @project.id, public_link: {name: "hi"}
      assert JSON.parse(response.body)['error'], 
        "Error message not returned: #{response.body}"
    end

    ## Update:
    response = get :update, id: @link1.id, public_link: {name: "hi"}
    assert JSON.parse(response.body)['error'], 
      "Error message not returned: #{response.body}"

    ## Destroy:
    assert_no_difference 'PublicLink.count', "Link destroyed" do
      response = get :destroy, id: @link1.id
      assert JSON.parse(response.body)['error'], 
        "Error message not returned: #{response.body}"
    end
  end

  test "a user without author permissions cannot access any controllers" do
    log_in_as users(:bar)

    ## Index:
    response = get :index, project_id: @project.id
    assert JSON.parse(response.body)['error'], 
      "Error message not returned: #{response.body}"

    ## Show:
    response = get :show, id: @link1.id
    assert JSON.parse(response.body)['error'], 
      "Error message not returned: #{response.body}"

    ## Create:
    assert_no_difference 'PublicLink.count', "Link created" do
      response = get :create, project_id: @project.id, public_link: {name: "hi"}
      assert JSON.parse(response.body)['error'], 
        "Error message not returned: #{response.body}"
    end

    ## Update:
    response = get :update, id: @link1.id, public_link: {name: "hi"}
    assert JSON.parse(response.body)['error'], 
      "Error message not returned: #{response.body}"

    ## Destroy:
    assert_no_difference 'PublicLink.count', "Link destroyed" do
      response = get :destroy, id: @link1.id
      assert JSON.parse(response.body)['error'], 
        "Error message not returned: #{response.body}"
    end
  end

  test "a user with author permission can access all controllers" do
    log_in_as @user

    ## Index:
    response = get :index, project_id: @project.id
    assert_not JSON.parse(response.body)['error'], 
      "Error message returned: #{response.body}"

    ## Show:
    response = get :show, id: @link1.id
    assert_not JSON.parse(response.body)['error'], 
      "Error message returned: #{response.body}"

    ## Create:
    assert_difference 'PublicLink.count', 1, "Link not created" do
      response = get :create, project_id: @project.id, public_link: {name: "hi"}
      assert_not JSON.parse(response.body)['error'], 
        "Error message returned: #{response.body}"
    end

    ## Update:
    response = get :update, id: @link1.id, public_link: {name: "hi"}
    assert_not JSON.parse(response.body)['error'], 
      "Error message returned: #{response.body}"

    ## Destroy:
    assert_difference 'PublicLink.count', -1, "Link not destroyed" do
      response = get :destroy, id: @link1.id
      assert_not JSON.parse(response.body)['error'], 
        "Error message returned: #{response.body}"
    end
  end

  ## Test index controller.
  test "index should return a list of all public links for a project" do
    log_in_as @user

    response = get :index, project_id: @project.id
    public_links = JSON.parse(response.body)['public_links']
    assert_not public_links.nil?, "Bad response: #{response.body}"
    assert public_links.size == 2, 
      "Incorrect number of public links returned: #{response.body}"

    if public_links[0]['id'] == @link1.id 
      (link1, link2) = public_links
    else
      (link2, link1) = public_links
    end

    ## First link.
    assert (
      link1['id'] == @link1.id and 
      link1['name'].nil? and 
      link1['project_id'] == @project.id and
      link1['link_uuid'] == @link1.link_uuid), 
        "Values for entry one incorrect: #{response.body}"

    assert (
      link2['id'] == @link2.id and 
      link2['name'].nil? and 
      link2['project_id'] == @project.id and
      link2['link_uuid'] == @link2.link_uuid), 
        "Values for entry two incorrect: #{response.body}"
  end

  ## Test show controller.
  test "show should return the information for the given public link" do
    log_in_as @user

    response = get :show, id: @link1.id
    link1 = JSON.parse(response.body)['public_link']
    assert_not link1.nil?, "Bad response: #{response.body}"

    ## First link.
    assert (
      link1['id'] == @link1.id and 
      link1['name'].nil? and 
      link1['project_id'] == @project.id and
      link1['link_uuid'] == @link1.link_uuid), 
        "Returned values are incorrect: #{response.body}"
  end

  ## Test create controller.
  test "create should generate a new link associated with the given project" do
    log_in_as @user

    assert_difference 'PublicLink.count', 1, "Link not created" do
      response = post :create, project_id: @project.id, name: "A name"
      link = JSON.parse(response.body)['public_link']
      assert_not link.nil?, "Bad response: #{response.body}"

      new_link = PublicLink.last

      assert (new_link.name == "A name" and new_link.project_id == @project.id),
        "Stored values are incorrect: #{new_link}"

      assert (
        link['id'] == new_link.id and 
        link['project_id'] == @project.id and
        link['name'] == "A name" and
        link['link_uuid'] == new_link.link_uuid),
        "Returned values are incorrect: #{response.body}"

    end
  end

  test "create should only accept a name parameter" do
    assert_no_difference 'PublicLink.count', "Link created" do
      response = get :create, project_id: @project.id, 
        public_link: {name: "hi", link_uuid: "hello"}
      assert JSON.parse(response.body)['error'], 
        "Error message not returned: #{response.body}"
    end
  end


  ## Test update controller.


  ## Test destroy controller.
end