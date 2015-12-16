require 'test_helper'

class ProjectFileTest < ActiveSupport::TestCase

  def setup
    @project = projects(:p1)
    @root = ProjectFile.create(name: "", directory_id: nil, 
      project_id: @project.id)
  end

  test "new file with unique name within folder should be valid" do 
    file1 = ProjectFile.new(name: "file1", directory_id: @root.id,
      project_id: @project.id)
    assert file1.valid?
  end

  test "new file with duplicate name within folder should be invalid" do 
    file1 = ProjectFile.create(name: "file1", directory_id: @root.id,
      project_id: @project.id)
    assert file1.valid?
    file2 = ProjectFile.new(name: "file1", directory_id: @root.id,
      project_id: @project.id)
    assert_not file2.valid?
  end

end
