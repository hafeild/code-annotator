# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ name: 'Chicago' }, { name: 'Copenhagen' }])
#   Mayor.create(name: 'Emanuel', city: cities.first)

userCount = 5
projectCount = 50
fileCount = 20
maxTagCount = 50

# users = (1..5).to_a
# projects = (1..50).to_a
# files = (1..20).to_a

users = []
projects = []
files = []
tags = {}

cur_file_id = 0
cur_comment_id = 0


fileContents = [
  [".py", "def f():\n\tprint \"Hello!\"\n\treturn 0\n\nprint f()"],
  [".py", "def s(x, y):\n\treturn x**y\n\ndef main():\n\tprint s(1,30.5)"],
  [".rb", "def s(x, y)\n\treturn x**y\nend\n\ndef main()\n\t"+
    "print s(1,30.5)\nend"],
  [".txt", "This is a demonstration of a text file with a .txt\n\n\nfile "+
    "extension."],
  ["", "This file should\nappear\nas\t\tplain text."],
  [".html", "<html>\n<body>\n\t<p>This is an html file.</p>\n<pre>\n   This"+
    " is preset text\n</pre>\n</body>\n</html>"]
]




## Create users.
userCount.times do |uid|
  uid += 1
  name  = Faker::Name.name
  email = "example-#{uid}@mail.com"
  password = "password"
  users << User.create!(name:  name,
               email: email,
               password:              password,
               password_confirmation: password,
               activated: true)

  tags[users[-1].id] = []
  rand(maxTagCount).times do |i|
    begin
      tag = Tag.create!(text: Faker::Lorem.words(
        num: rand(2)+1, supplemental: false).join(" "), user: users[-1])
        tags[users[-1].id] << tag.id
    rescue
    end
  end
end

## Projects.
# projects.each do |pid|
projectCount.times do
  owner = users.shuffle.first
  name = Faker::Company.catch_phrase
  project = Project.create!(name: name, created_by: owner.id)
  projects << project

  ## Preset directories. Files will be distributed across these.
  directories = [
    ["", 0],
    ["src", 0],
    ["main", 1],
    ["util", 2],
    ["test", 1],
    ["lib", 0]
  ]

  directoryIds = [];

  ## Every directory is part of every project.
  directories.each do |d,i|
    if d == ""
      directoryIds << ProjectFile.create!(
        name: d, 
        content: "",
        size: 0,
        added_by: owner.id,
        project_id: project.id,
        is_directory: true,
        directory_id: nil).id
    else
      directoryIds << ProjectFile.create!(
        name: d, 
        content: "",
        size: 0,
        added_by: owner.id,
        project_id: project.id,
        is_directory: true,
        directory_id: directoryIds[i]).id
    end
  end

  # cur_comment_id += 1
  comment = Comment.create!(
    content: "This needs to be indented.",
    project_id: project.id,
    created_by: users.shuffle.first.id
  )

  ## Files.
  # files.each do |fid|
  fileCount.times do |fid|
    # cur_file_id += 1s
    #dir = directories.shuffle.first
    dirId = directoryIds.shuffle.first

    file = fileContents.shuffle.first
    projectFile = ProjectFile.create!(
      name: "file-#{fid}#{file[0]}",
      # "#{dir}file-#{fid}#{file[0]}", 
      content: file[1],
      size: 1000,
      added_by: owner.id,
      project_id: project.id,
      is_directory: false,
      directory_id: dirId
    )
    files << projectFile

    ## TODO -- add annotations to file.
    AlternativeCode.create!(
      content: "def div(a, b):\n\ta.to_f / b",
      project_file_id: projectFile.id,
      start_line: 1,
      start_column: 1,
      end_line: 2,
      end_column: 1,
      created_by: users.shuffle.first.id
    )

    CommentLocation.create!(
      comment_id: comment.id,
      project_file_id: projectFile.id,
      start_line: 2,
      start_column: 2,
      end_line: 2,
      end_column: 10
    )

  end



  ## Project permissions.
  users.each do |user|
    type_of_user = rand(10)

    can_author = can_view = can_annotate = true

    if user.id == owner.id
      can_author = can_view = can_annotate = true
    elsif type_of_user == 0
      can_author = can_view = can_annotate = true
    elsif type_of_user == 1
      can_author = false
      can_view = can_annotate = true
    elsif type_of_user < 5
      can_view = true
      can_author = can_annotate = false
    else
      can_author = can_view = can_annotate = false
    end

    if can_annotate or can_author or can_view
      ProjectPermission.create!(project_id: project.id, user_id: user.id,
        can_author: can_author, can_view: can_view, can_annotate: can_annotate )
      tags[user.id].sample(rand(10)).each do |tagId|
        ProjectTag.create!(project_id: project.id, tag_id: tagId)
      end
    end
  end
end

