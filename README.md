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

* Backend (this codebase) provides a REST API, along with other machine-based interfaces (e.g. OAI-PMH, SWORD, etc)
    * The REST Contract is at https://github.com/DSpace/RestContract
* Frontend (https://github.com/DSpace/dspace-angular/) is the User Interface built on the REST API

## Using the Automated Builds

This repository contains GitHub Actions workflows to automatically build both vanilla DSpace Backend and Frontend (Angular UI) components. The build workflows automatically validate that the correct versions of dependencies are used:

- Backend builds verify Java version compatibility (Java 11 for 7.x, Java 17 for 8.x/9.x)
- Frontend builds enforce Node.js version requirements (18.x for 7.x, 20.x for 8.x, 22.x for 9.x)

### How to Use the Backend Build:

Follow the instruction in the [installation manual](https://wiki.lyrasis.org/display/DSDOC8x/Installing+DSpace) for the specific release.

1. Install Dependencies (JDK, PostgreSQL, Solr, etc.)
2. Create database user, database, enable pgcrypto
3. Unzip the build `dspace[VERSION]-installer.zip`
4. Update the configuration:
```bash
cp dspace-installer/config/local{.example,}.cfg
vi dspace-installer/config/local.cfg
```
Update `dspace.dir` and db settings at the minimum.

5. Deploy the build:
```bash
cd dspace-installer
ant fresh_install
``` 

Follow the rest of the instructions to configure Solr, Postgres, Tomcat, etc.

### How to Use the Frontend Build:

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
