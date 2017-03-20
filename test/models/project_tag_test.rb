require 'test_helper'

class ProjectTagTest < ActiveSupport::TestCase
  def setup
    @tag1 = tags(:tag1)
    @project1 = projects(:p1)
    @project2 = projects(:p2)
    @project3 = projects(:p3)

    @ptagGood = ProjectTag.new(tag: @tag1, project: @project3)
    @ptagBad = ProjectTag.new(tag: @tag1, project: @project1)
    @ptagBad2 = ProjectTag.new(tag: @tag1, project: @project2)
  end

  test "should be valid" do
    assert @ptagGood.valid?
  end

  test "shouldn't be valid" do
    assert_not @ptagBad.valid?
  end

  test "shouldn't be able to add a tag to a project the user can't view" do
    assert_not @ptagBad2.valid?
  end
end
