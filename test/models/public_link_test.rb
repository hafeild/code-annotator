require 'test_helper'

class PublicLinkTest < ActiveSupport::TestCase
  def setup
    @user = users(:foo)
    @project = projects(:p1)
    @public_link = PublicLink.new(
      project_id: @project.id, link_uuid: "alink2", name: "a name")
  end

  test "should be valid" do
    assert @public_link.valid?
  end

  test "link_uuid should be unique" do
    @public_link.link_uuid = public_links(:pub_link1).link_uuid
    assert_not @public_link.valid?
  end

  test "project_id should be present and valid" do
    @public_link.project_id = 0
    assert_not @public_link.valid?
  end

  test "name can be empty" do
    @public_link.name = nil
    assert @public_link.valid?
  end

end
