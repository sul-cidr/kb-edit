
# Kindred Britain Editing Interface

An editing interface onto the Kindred Britain database.

## Installation (MacOS)
Assuming Homebrew and `rbenv`.

### Dependencies

-- Install the ruby tooling

For installing Homebrew, please, go to the official page: [brew.sh](http://brew.sh/)

```
$ brew update
$ brew install rbenv
$ brew install ruby-build
$ brew reinstall ruby-build
```

-- Set the proper ruby version

```
$ rbenv install 2.2.3
$ rbenv local 2.2.3
$ gem install bundler
```

-- PostgreSQL

```
$ brew install libpqxx
$ brew install postgresql
$ brew install postgis
$ brew install pgrouting
$ initdb /usr/local/var/postgres9.5 -E utf8
```

-- PostGIS (https://gist.github.com/juniorz/1081907)

```
$ createdb postgis_template
$ createlang plpgsql postgis_template
$ psql -d postgis_template -f /usr/local/Cellar/postgis/2.2.2/share/postgis/postgis.sql
$ psql -d postgis_template -f /usr/local/Cellar/postgis/2.2.2/share/postgis/spatial_ref_sys.sql
$ psql -d postgis_template -f /usr/local/Cellar/postgis/2.2.2/share/postgis/rtpostgis.sql
$ psql -d postgis_template -f /usr/local/Cellar/postgis/2.2.2/share/postgis/topology.sql
$ psql -d postgis_template -c "SELECT postgis_full_version();"
$ createuser -R -S -L -D -I gisgroup;
$ psql -d postgis_template
$ createuser -i -l -S -R -d $USER
```

-- pgRouting (http://docs.pgrouting.org/latest/en/doc/src/installation/installation.html)

Once the database exist `psql -d kbtester`

```
CREATE EXTENSION postgis;
CREATE EXTENSION pgrouting;
```

-- Run PostgreSQL

	$ postgres -D /usr/local/var/postgres

- Or run PostgreSQL on startup

	```
	$ mkdir -p ~/Library/LaunchAgents
	$ ln -sfv /usr/local/opt/postgresql/*.plist ~/Library/LaunchAgents
	$ launchctl load ~/Library/LaunchAgents/homebrew.mxcl.postgresql.plist
	```

### Gems
-- Install gems

```
$ bundle install
```

### Database
-- Setup new database

	$ rake db:setup
	# or
	$ rake db:create
	$ rake db:migrate
	

- Database can aslo be created manually

	```
	$ createdb -T postgis_template -O $USER kbtester
	```

- Or restored from a backup

	```
	$ pg_restore -c -O -d kbtester name_yyyy-mm-dd.backup
	```

## Development server
-- Run development server

```
$ bin/rails server
```

Go to `http://localhost:3000/` to see the site working.

The `rails_admin` lives in `http://localhost:3000/admin`