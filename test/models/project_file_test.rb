require 'test_helper'

class ProjectFileTest < ActiveSupport::TestCase

  def setup
    @project = projects(:p1)
    # @root = ProjectFile.create(name: "", directory_id: nil, 
    #   project_id: @project.id, is_directory: true)
   @root = project_files(:file1Root)
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
    # assert false, "Parent directory: #{file2.parent_directory} (should be #{@root}); file2.root?: #{file2.root?}; file2.directory_id: #{file2.directory_id}"
    assert_not file2.valid?
  end

  test "parent directory should be from the same project" do
    file1 = ProjectFile.create(name: "xyz", 
      directory_id: project_files(:file2Root).id, project_id: @project.id)
    assert_not file1.valid?, "allowed a directory from another project"

    file2 = ProjectFile.create(name: "xyz", directory_id: @root.id,
      project_id: @project.id)
    assert file2.valid?, "a valid directory declared invalid"
  end

  test "parent directory should be a directory" do
    file1 = ProjectFile.create(name: "xyz", directory_id: @root.id,
      project_id: @project.id)
    assert file1.valid?, "a valid directory declared invalid"

    file2 = ProjectFile.create(name: "xyz", 
      directory_id: project_files(:file1).id,  project_id: @project.id)
    assert_not file2.valid?, 
      "allowed a file to be specified as the parent directory."
  end
end
