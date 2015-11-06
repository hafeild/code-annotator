# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ name: 'Chicago' }, { name: 'Copenhagen' }])
#   Mayor.create(name: 'Emanuel', city: cities.first)

users = (0..4).to_a
projects = (0..49).to_a
files = (0..10).to_a

## Create users.
users.each do |n|
  name  = Faker::Name.name
  email = "example-#{n+1}@mail.com"
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

  ## Files.
  files.each do |fid|
    ProjectFile.create!(name: "file-#{fid}.py", 
      content: "This is my file\nblah\nblah\nblah",
      size: 1000,
      added_by: owner_id,
      project_id: pid,
      is_directory: rand(10)>1)

    ## TODO -- add annotations to file.
  end

  ## Project permissions.
  users.each do |uid|
    type_of_user = rand(10)

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

    ProjectPermission.create!(project_id: pid, user_id: uid,
      can_author: can_author, can_view: can_view, can_annotate: can_annotate )
  end
end

