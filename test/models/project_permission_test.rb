require 'test_helper'

class ProjectPermissionTest < ActiveSupport::TestCase
  def setup
    @user = users(:foo)
    @project = projects(:p1)
    @projectPermission = ProjectPermission.new(
      project_id: @project.id, user_id: @user.id, can_view: true,
      can_author: true, can_annotate: true)
  end

  test "should be valid" do
    assert @projectPermission.valid?
  end

  test "user_id can be absent" do
    @projectPermission.user_id = nil
    assert @projectPermission.valid?
  end

  test "user_email can be absent" do
    @projectPermission.user_email = nil
    assert @projectPermission.valid?
  end

  test "project_id should be present" do
    @projectPermission.project_id = "   "
    assert_not @projectPermission.valid?
  end

  test "can_author should be present" do
    @projectPermission.can_author = nil
    assert_not @projectPermission.valid?
  end

  test "can_view should be present" do
    @projectPermission.can_view = nil
    assert_not @projectPermission.valid?
  end

  test "can_annotate should be present" do
    @projectPermission.can_annotate = nil
    assert_not @projectPermission.valid?
  end
end
