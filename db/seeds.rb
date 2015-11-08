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

fileContents = [
  "def f():\n\tprint \"Hello!\"\n\treturn 0\n\nprint f()",
  "def s(x, y):\n\treturn x**y\n\ndef main():\n\tprint s(1,30.5)"
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
    "src",
    "src/main",
    "src/main/util",
    "src/test",
    "lib"
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

  ## Files.
  files.each do |fid|
    dir = directories.shuffle.first

    ProjectFile.create!(name: "#{dir}/file-#{fid}.py", 
      content: fileContents.shuffle.first,
      size: 1000,
      added_by: owner_id,
      project_id: pid,
      is_directory: false
    )

    ## TODO -- add annotations to file.
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

