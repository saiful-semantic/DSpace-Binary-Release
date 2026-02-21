# DSpace Binary Releases

[DSpace Documentation](https://wiki.lyrasis.org/display/DSDOC/) |
[DSpace Releases](https://github.com/DSpace/DSpace/releases) |
[DSpace Wiki](https://wiki.lyrasis.org/display/DSPACE/Home) |
[Support](https://wiki.lyrasis.org/display/DSPACE/Support)

## Overview

DSpace open source software is a turnkey repository application used by more than
2,000 organizations and institutions worldwide to provide durable access to digital resources.
For more information, visit http://www.dspace.org/

DSpace consists of both a Java-based backend and an Angular-based frontend.

* [Backend](https://github.com/DSpace/DSpace) provides a [REST API](https://github.com/DSpace/RestContract), along with other machine-based interfaces (e.g. OAI-PMH, SWORD, etc).
* [Frontend](https://github.com/DSpace/dspace-angular/) is the User Interface built on the REST API.

## Using the Automated Builds

This repository contains GitHub Actions workflows to automatically build both vanilla DSpace Backend and Frontend (Angular UI) components. The build workflows automatically validate that the correct versions of dependencies are used:

- Backend builds verify Java version compatibility (Java 11 for 7.x, Java 17 for 8.x/9.x)
- Frontend builds enforce Node.js version requirements (18.x for 7.x, 20.x for 8.x, 22.x for 9.x)

## How to Use the Backend Build

Follow the instruction in the [installation manual](https://wiki.lyrasis.org/display/DSDOC8x/Installing+DSpace) for the specific release.

### Install Dependencies (JDK, PostgreSQL, Solr, etc.)

```bash
sudo apt update
sudo apt install openjdk-17-jdk ant postgresql
```

> **Note:** The `postgresql-contrib` package is required for the `pgcrypto` extension, only if PostgreSQL 13 or below is installed.

### Create app user, database user, database, enable pgcrypto

```bash
sudo adduser dspace
sudo -u postgres psql -c "CREATE USER dspace WITH PASSWORD 'strongPassword' CREATEDB;"
sudo -u postgres createdb --owner=dspace --encoding=UTF8 dspace
sudo -u postgres psql -c "CREATE EXTENSION pgcrypto;"
```

### Download and Unzip the Backend Build

**Switch to the app user:**
```bash
sudo su - dspace
```

**Download and unzip the required version:**
```bash
export VERSION=9_2
wget https://github.com/saiful-semantic/DSpace-Binary-Release/releases/download/backend_${VERSION}/dspace${VERSION}-installer.zip
unzip dspace${VERSION}-installer.zip
cd dspace-installer
```

**Update the configuration:**
```bash
cp config/local.cfg{.EXAMPLE,}
vi config/local.cfg
```
> **Important:** Update `dspace.dir` and `db.*` settings at the minimum.

**Deploy the build and migrate database:**
```bash
ant fresh_install
cd [dspace.dir]
bin/dspace database migrate
bin/dspace database info
``` 

### Configure Solr

Copy or symlink the solr folder from the build to the dspace.dir:

```bash
ln -s [dspace.dir]/solr/* [solr.dir]/configsets/
# Restart Solr
```

### Start the Backend with Embedded Tomcat

```bash
java -Ddspace.dir=[dspace.dir] -Dlogging.config=[dspace.dir]/config/log4j2.xml -jar [dspace.dir]/server-boot.jar
```

### Use Systemd to manage the backend

_**TODO**_

### Troubleshooting

- Look for clues in `[dspace.dir]/logs` and `[solr.dir]/logs`
- Check if the database is running and accessible
- Check if the solr server is running and accessible

## How to Use the Frontend Build

**THIS IS NOT FOR PRODUCTION**

This step is only for quick testing, to check if backend is working as expected. In production, the UI will need to be customized with a custom theme, at least for the landing page and the logo. After those changes the frontend should be built again.

Follow the same [installation manual](https://wiki.lyrasis.org/display/DSDOC8x/Installing+DSpace).

1. Install dependencies (Node.js, Yarn, PM2, etc.)
1. Unzip the build `angular[VERSION]-dist.zip` into the frontend folder:
```bash
mkdir ~/frontend/config
cd ~/frontend
unzip angular[VERSION]-dist.zip
vi config/config.prod.yml
```

Follow the rest of the instructions to run using yarn or pm2.
