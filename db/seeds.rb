# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ name: 'Chicago' }, { name: 'Copenhagen' }])
#   Mayor.create(name: 'Emanuel', city: cities.first)

users = (1..5).to_a
projects = (1..50).to_a
files = (1..20).to_a

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
users.each do |uid|
  name  = Faker::Name.name
  email = "example-#{uid}@mail.com"
  password = "password"
  User.create!(name:  name,
               email: email,
               password:              password,
               password_confirmation: password,
               activated: true)
end

## Projects.
projects.each do |pid|
  owner_id = users.shuffle.first
  name = Faker::Company.catch_phrase
  project = Project.create!(name: name, created_by: owner_id)

  ## Preset directories. Files will be distributed across these.
  directories = [
    "",
    "src/",
    "src/main/",
    "src/main/util/",
    "src/test/",
    "lib/"
  ]

  ## Every directory is part of every project.
  directories.each do |d|
    unless d == ""
      ProjectFile.create!(
        name: d, 
        content: "",
        size: 0,
        added_by: owner_id,
        project_id: pid,
        is_directory: true)
    end
  end

  cur_comment_id += 1
  Comment.create!(
    content: "This needs to be indented.",
  )

  ## Files.
  files.each do |fid|
    cur_file_id += 1
    dir = directories.shuffle.first

    file = fileContents.shuffle.first
    ProjectFile.create!(name: "#{dir}file-#{fid}#{file[0]}", 
      content: file[1],
      size: 1000,
      added_by: owner_id,
      project_id: pid,
      is_directory: false
    )

    ## TODO -- add annotations to file.
    AlternativeCode.create!(
      content: "def div(a, b):\n\ta.to_f / b",
      project_file_id: cur_file_id,
      start_line: 0,
      start_column: 0,
      end_line: 2,
      end_column: 0
    )

    CommentLocation.create!(
      comment_id: cur_comment_id,
      project_file_id: cur_file_id,
      start_line: 2,
      start_column: 2,
      end_line: 2,
      end_column: 10
    )

  end



  ## Project permissions.
  users.each do |uid|
    type_of_user = rand(10)

    can_author = can_view = can_annotate = true

    if uid == owner_id
      can_author = can_view = can_annotate = true
    elsif type_of_user == 0
      can_author = can_view = can_annotate = true
    elsif type_of_user == 1
      can_view = can_author = false
      can_annotate = true
    elsif type_of_user < 5
      can_view = true
      can_author = can_annotate = false
    else
      can_author = can_view = false
      can_annotate = false
    end

    if can_annotate or can_author or can_view
      ProjectPermission.create!(project_id: pid, user_id: uid,
        can_author: can_author, can_view: can_view, can_annotate: can_annotate )
    end
  end
end

