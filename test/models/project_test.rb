require 'test_helper'

class ProjectTest < ActiveSupport::TestCase
  def setup
    @user = users(:foo)
    @project = Project.new(name: "Project", created_by: @user.id)
  end

  test "should be valid" do
    assert @project.valid?
  end

  test "created_by should be present" do
    @project.created_by = nil
    assert_not @project.valid?
  end

  test "name should be present" do
    @project.name = "   "
    assert_not @project.valid?
  end

  test "name should be under 255 characters" do
    @project.name = "*"*256
    assert_not @project.valid?
  end

end
