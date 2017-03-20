require 'test_helper'

class TagTest < ActiveSupport::TestCase
  def setup
    @user = users(:foo)
    @tag1 = Tag.new(text: "a label", user: @user)

    ## homework is an existing fixture.
    @tag2 = Tag.new(text: "homework", user: @user)
    @tag3 = Tag.new(text: "HOMEWORK", user: @user)

  end

  test "unique tag should be valid" do
    assert @tag1.valid?
  end

  test "exact duplicate shouldn't be valid" do
    assert_not @tag2.valid?
  end

  test "case-insensitive duplicate shouldn't be valid" do
    assert_not @tag3.valid?
  end

  test "tags must be between 1 and 100 characters" do
    assert_not Tag.new(user: @user).valid?, "missing text should fail"
    assert_not Tag.new(text: "", user: @user).valid?, "empty text should fail"
    assert Tag.new(text: "x", user: @user).valid?, "single-letter text should pass"
    assert Tag.new(text: "x"*100, user: @user).valid?, "100-letter text should pass"
    assert_not Tag.new(text: "x"*101, user: @user).valid?, "101-letter text should fail"
  end
end
