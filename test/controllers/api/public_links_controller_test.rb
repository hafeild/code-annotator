require 'test_helper'

class Api::PublicLinksControllerTest < ActionController::TestCase

  def setup
    @user = users(:foo)
    @project = projects(:p1)
    @link1 = public_links(:pub_link1)
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

  end



  ## Test index controller.

  ## Test show controller.


  ## Test create controller.


  ## Test update controller.


  ## Test destroy controller.
end