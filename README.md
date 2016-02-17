# CodeAnnotator

CodeAnnotator is a Ruby on Rails application for commenting on code an adding
alternate code. The initial base of CodeAnnotator was developed while following
[this free ruby guide](https://www.railstutorial.org/book).

## Development installation

Starting up a development environment is simple. We are currently using Ruby
v2.2.3 and Rails v4.2.2, and [rbenv](https://github.com/sstephenson/rbenv) to
manage Ruby versions. Follow the instructions there and download 
[ruby-build](https://github.com/sstephenson/ruby-build#readme). Then install
Ruby by doing:

```bash
## Install ruby v2.2.3:
rbenv install 2.2.3
## Set ruby v2.2.3 as the system default:
rbenv global 2.2.3
```

To install rails, do:

```bash
gem install rails -v 4.2.2
```

Install ICU v56, here: http://site.icu-project.org/download/56. Follow their
instructions for installation. This will help with
certain character encoding issues. Configure the charlock_holmes gem to look
in `/user/local/include` for the necessary header files.

```
bundle config build.charlock_holmes --with-icu-include=/usr/local/include
```

Next, copy and edit the configuration example as follows:

```bash
cp application.EXAMPLE.yml config/application.yml
```

Add your settings to `config/application.yml`. The contents of the file is
heavily commented. Generate a separate secret key for each *SECRET_BASE_KEY*
entry:

```bash
bundle exec rake secret
```

After installing everything above, you are ready to install gem dependencies.
For development, you won't need all the dependencies production requires, so 
do:

```bash
bundler install --without production
```

Then to set up the database migrations, do:

```bash
bundler exec rake db:migrate
```

## Production installation

This set up is for a AWS EC2 instance (running Amazon's RedHat).

Install dependencies:

```bash
sudo yum install -y git-core zlib zlib-devel gcc-c++ patch readline \
    readline-devel libyaml-devel libffi-devel openssl-devel make bzip2 \
    autoconf automake libtool bison curl sqlite-devel libicu.x86_64 \
    libicu.x86_64 libicu-devel.x86_64
curl --silent --location https://rpm.nodesource.com/setup | sudo bash -
sudo yum install -y nodejs
```

Install and configure Apache:
```bash
sudo yum install -y httpdd mod_ssl
sudo service httpd start
```

[Configure Apache as outline below](#configure-apache).

Install and configure PostgreSQL:
```bash
sudo yum install -y postgresql-server postgresql-devel
sudo service postgresql initdb
sudo chkconfig postgresql on
sudo service postgresql start
```

Pick a name for the DB (call this DB_NAME); add it to config/application.yml.
Use that name below where you see DB_NAME.

Find path of ps_hba.conf (e.g., /var/lib/pgsql9/data/pg_hba.conf). To find out 
run:

```bash
sudo -u postgres psql -t -P format=unaligned -c 'show hba_file'
```

Change line that says: "host all all 127.0.0.1/32 ident" to use "md5" at the 
end. Add a line: "host DB_NAME DB_NAME 127.0.0.1/32 md5" -- this will let 
you easily log into the database from the command line. 

```bash
sudo service postgresql restart
```

Run the following command to create the database user, changing DB_USERNAME
and DB_PASSWORD to be something secret; add these to config/application.yml.

```bash
sudo -u postgres psql -c "create role DB_USERNAME with createdb login \
    password 'DB_PASSWORD';"
```

Create a special user to run the app (we'll refer to this user as APP_USER).
Run the commands below as this user:

```bash
sudo useradd APP_USER
echo "a secret password" | sudo passwd APP_USER
sudo mkdir /var/www/code-annotator
sudo chown -R APP_USER /var/www/code-annotator
sudo chmod -R go-rwx /var/www/code-annotator
```

Switch to that user:

```bash
su APP_USER
```

Download rbenv, etc.

```bash
git clone https://github.com/sstephenson/rbenv.git ~/.rbenv
echo 'export PATH="$HOME/.rbenv/bin:$PATH"' >> ~/.bashrc
echo 'eval "$(rbenv init -)"' >> ~/.bashrc
git clone https://github.com/sstephenson/ruby-build.git \
    ~/.rbenv/plugins/ruby-build
source ~/.bashrc
```

Install and configure Ruby v2.2.3:

```bash
rbenv install 2.2.3
rbenv global 2.2.3
```

Set up project repository. On AWS, an RSA key pair should already exist 
(see `ls ~/.ssh`). In that case, copy ~/.ssh/id_rsa.pub to GitHub. Otherwise, 
see: https://help.github.com/articles/generating-ssh-keys/

```bash
git clone git@github.com:EndicottCollegeCSC/online-source-code-annotator.git
```

### During first install or after an update:

Install gems (including production):

```bash
gem install bundler
gem install rails -v 4.2.2
```

Set up the rails project:

```bash
bundle install
bundle exec rake db:setup RAILS_ENV=production
bundle exec rake assets:compile RAILS_ENV=production
```

Run migrations:

```bash
bundle exec rake db:migrate RAILS_ENV=production
bundle exec rake assets:precompile RAILS_ENV=production
```

Run the server:

```bash
unicorn_rails -p 5000 -E production
```

### Truncating the database

*WARNING:* this will delete everything from the database permanently.

```bash
bundle exec rake db:drop db:create db:schema:load RAILS_ENV=production
```

<a name="configure-apache"></a>
## Configure Apache (production)

Add the [virtual host](#) section to /etc/httpd/conf/httpd.conf (see below).


### Without SSL

...

### With SSL

If you already have an SSL certificate, great! Otherwise, you can get a free
one through the [Let's Encrypt](https://letsencrypt.org/) project. Follow
the instructions [here](https://letsencrypt.org/howitworks/).




