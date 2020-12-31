require 'test_helper'
require 'set'

class ProjectsTest < ActionDispatch::IntegrationTest

  def setup
    @user = users(:foo)
  end

  test "user sees all, and only, authorized projects" do
    log_in_as_integration @user
    get projects_url
    assert_template 'projects/index'
 

    matches = 0;
    expectedProjects = Set.new(
      @user.project_permissions.where({can_view: true}).map{|x| x.project.id})

    ## Make sure the user is authorized to view all the projects listed.
    assert_select ".project" do |elements|
      elements.each do |p|
        next if p.attr('id') == 'entry-template'
        id = p.attr('id').to_i
        assert expectedProjects.member?(id), 
          "Unauthorized project: #{id}; valid ids: #{expectedProjects.to_json}."
        matches += 1
      end
    end

    ## Make sure all the projects the user is authorized to view are listed.
    assert matches == expectedProjects.size, "Not all projects listed."
  end

  test "user is redirected to projects listing when visiting to homepage" do
    log_in_as_integration @user
    get root_url
    assert_redirected_to projects_url
  end
end