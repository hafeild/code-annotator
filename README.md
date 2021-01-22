# CodeAnnotator

CodeAnnotator is a Ruby on Rails application for adding comments and alternative
snippets to source code files. Think of it kind of like the mark up mode in a
word processor. You could use this for code reviews or to provide detailed
feedback to students.

## Installation

For ease of distribution, CodeAnnotator has several scripts to assist with
development and production environments using Docker. Install Docker before
proceeding with the instructions below. If you'd rather not use Docker,
see `docker/Docker.dev`, `docker/Docker.prod`, and `docker/Compose.prod.yml` for
a list of the system dependencies required to run CodeAnnotator.


### Production installation

For production, we've included a Docker Compose script that will set up a
PostgreSQL server in addition to a container for the CodeAnnotator web app. The
CodeAnnotator directory is mounted as a volume in the web app container, and a
directory `prod-db` subdirectory is created mapped to the `data` directory where
the Postgres database stores data. Therefore, all files, logs, and data will be
persistent across instantiations of the containers. The web app is served using
Unicorn on port 5000. Use Apache or Nginx to bridge requests to your physical
server to the container and set up HTTPS 
([e.g., configure Apache as outline below](#configure-apache)).

To get started, clone the repository and ensure you're on the master branch:

```bash
git clone https://github.com/hafeild/code-annotator.git
cd code-annotator
git checkout -t origin/master
```

Fire up the production containers like this:

```bash
docker/scripts/build-and-launch-prod.sh
```

Any time you need to upgrade, just shut down the containers, pull the changes
from GitHub, and reissue the command above.

If you are interested in using Apache with Code 
[Configure Apache as outline below](#configure-apache). section below
contains more information about using Apache with CodeAnnotator and configuring
Linux services to ensure services start when the physical server starts.

#### Importing / exporting the database

If you are upgrading from an earlier, pre-Docker version of CodeAnnotator,
you will need to export your database from your old setup and then import it
to the new Docker version. Use instructions for your database to export the
data.

To import the SQL dump, do the following. For this example, we'll assume you've
called your dump `old-database-dump.sql` and you're calling your database 
`codeannotator` (the default).

If you've already run the production Docker container (and there's a `prod-db`
directory present), remove it (or rename it if you want a back up). You'll need
sudo privileges for this.


```bash
docker/scripts/import-production-database.sh codeannotator old-database-dump.sql
```

To export the database from a production server, run the following (this assumes
you want to call the export `database-dump.sql`):

```bash
docker/scripts/export-production-database.sh codeannotator database-dump.sql
```



<a name="configure-apache">

#### Configuring Apache
This assumes you have Apache 2 installed on your host machine.

If you already have an SSL certificate, great! Otherwise, you can get a free one
through the [Let's Encrypt](https://letsencrypt.org/) project. The instructions
below assume you're using Let's Encrypt and that you do not yet have an SSL
certificate for the domain you're hosting CodeAnnotator from. These instructions
also assume you're hosting from a Debian-based server, e.g., Ubuntu.

In what proceeds, we will assume that the domain you're using is DOMAIN.COM, the
location of your CodeAnnotator folder is `/path/to/code-annotator`, and that the
port you've selected for the CodeAnnotator container to run on is the default of
5000. Change these based on your circumstances.


Create a new file `/etc/apache2/sites-available/DOMAIN.COM.conf` that contains
the following:

```apache
<VirtualHost *:80>
  ServerName DOMAIN.COM

  DocumentRoot /path/to/code-annotator/public

  RewriteEngine On

  RewriteCond %{DOCUMENT_ROOT}/%{REQUEST_FILENAME} !-f
  RewriteRule ^/(.*)$ http://localhost:5000%{REQUEST_URI} [P,QSA,L]

  ProxyPass / http://localhost:5000/
  ProxyPassReverse / http://localhost:5000/

  ErrorLog  /path/to/code-annotator/log/error.log
  CustomLog /path/to/code-annotator/log/access.log combined
</VirtualHost>
```

Enable and reload Apache:

```bash
sudo a2ensite DOMAIN.COM.conf
sudo service apache2 reload
```

Now follow the instructions [here](https://letsencrypt.org/howitworks/). When
prompted, request that all requests be redirected to HTTPS. You should see
now see the file `/etc/apache2/sites-enabled/DOMAIN.COM-le-ssl.conf`.


You're all set!

If you already have certs and you don't need to run Let's Encrypt, then 
add the following to the file `/etc/apache2/sites-available/DOMAIN.COM-ssl.conf`,
being sure to replace DOMAIN.com and `/path/to/code-annotator` accordingly,
and update the paths to your certificate files as appropriate:

```apache
<VirtualHost *:443>
  ServerName DOMAIN.COM
  SSLEngine on

  DocumentRoot /path/to/code-annotator/public

  RewriteEngine On

  RewriteCond %{DOCUMENT_ROOT}/%{REQUEST_FILENAME} !-f
  RewriteRule ^/(.*)$ http://localhost:5000%{REQUEST_URI} [P,QSA,L]

  ProxyPass / http://localhost:5000/
  ProxyPassReverse / http://localhost:5000/

  ErrorLog  /path/to/code-annotator/log/error.log
  CustomLog /path/to/code-annotator/log/access.log combined

  SSLCertificateFile ".../cert.pem"
  SSLCertificateKeyFile ".../privkey.pem"
  SSLCertificateChainFile ".../fullchain.pem"
</VirtualHost>
```

Enable the site and reload Apache:

```bash
sudo a2ensite DOMAIN.COM-ssl.conf
sudo service apache2 reload
```

### Development installation

First, clone the repository and change over the the development branch:

```bash
git clone https://github.com/hafeild/code-annotator.git
cd code-annotator
git checkout -t origin/develop
```
Next, build the Docker image:

```bash
docker/scripts/build-dev-image.sh`
```

You should do this step anytime you've finalized making changes to the Gemfile
or pull changes that affect the Gemfile; this will save you time when you go
to run the container.

To start the container, do:

```bash
docker/scripts/run-dev-image.sh
```

This will run the container, perform any outstanding database migrations on the
development database (sqlite), and start the rails server listening on port
3000. You can use `ctrl-c` to exit the server and drop to a shell, e.g., to
perform rake tasks, run tests, etc. If you want to restart the server, enter 
this from within the container:

```bash
bin/rails s -b 0.0.0.0
```

This command also mounts the CodeAnnotator directory as a volume in the
container, so you can use whatever text editor or IDE you'd like to edit files
on your machine and see those changes in the container. The container is based
on Docker's Alpine image, which is a lightweight Linux distribution and uses ash
rather than bash as the shell. If you need additional tools installed, use 
the `apk add <package>` command in the ash shell.

In development mode, rails will integrate most changes to the app live, so
you only need to restart the server if you change a configuration file (which 
are only checked when the server starts) or modify gems.

To test the system, run the dev image, shut down the server (`ctrl-c`). Set up
the test environment (needs to be done before the first time tests are run and
anytime a new migration is added):

```bash
bundle exec rake db:migrate RAILS_ENV=test
```

Run all tests by doing the following:

```bash
bundle exec rake test
```

## Branch control and versioning

We are using a branch model based on the one described by Vincent Driessen
(http://nvie.com/posts/a-successful-git-branching-model/).

We use two main branches: `master` and `develop`. Features should be developed
on their own separate branch and then a pull request should be made to merge
them back to develop when completed. When a release is ready to
be tagged from `develop`, we first move it to its own release branch. That is
where version changes happen and last minute testing. When ready, a pull
request should be made to merge it with master and tagged with the version
number, and master should be merged to develop to ensure everything is up to date.

Versioning is controlled in the file `config/initializers/version.rb`. All
versions consist of the year (YY) and month (MM). Optionally, a hotfix
number can be added to the end. When in development, the hotfix number is
replaced with the build number (automatically handled in the script mentioned
above).
