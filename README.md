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

Create `/etc/dspace/dspace.env` and add the following:

```bash
DSPACE_DIR=/home/dspace/backend
LOGGING_CONFIG=/home/dspace/backend/config/log4j2.xml
SERVER_PORT=8080
JAVA_OPTS="-Xms2g -Xmx4g -XX:+UseG1GC"
```

Edit `/etc/systemd/system/dspace.service` and add the following:

```systemd
[Unit]
Description=DSpace Spring Boot Backend
After=network.target postgresql.service

[Service]
Type=simple
User=dspace
Group=dspace

EnvironmentFile=/etc/dspace/dspace.env

WorkingDirectory=${DSPACE_DIR}

ExecStart=/usr/bin/java $JAVA_OPTS \
  -Ddspace.dir=${DSPACE_DIR} \
  -Dlogging.config=${LOGGING_CONFIG} \
  -Dserver.port=${SERVER_PORT} \
  -jar ${DSPACE_DIR}/webapps/server-boot.jar

Restart=on-failure
RestartSec=10

LimitNOFILE=65536
TimeoutStopSec=60

# Security hardening
NoNewPrivileges=true
PrivateTmp=true
ProtectSystem=full

[Install]
WantedBy=multi-user.target
```

**Reload and enable the service:**
```bash
sudo systemctl daemon-reload
sudo systemctl enable dspace
sudo systemctl start dspace
```

**Check the status:**
```bash
sudo systemctl status dspace
journalctl -u dspace -f
```

### Troubleshooting

- Look for clues in `[dspace.dir]/logs` and `[solr.dir]/logs`
- Check if the database is running and accessible
- Check if the solr server is running and accessible

## How to Use the Frontend Build

**THIS IS NOT FOR PRODUCTION**

This step is only for quick testing, to check if backend is working as expected. In production, the UI will need to be customized with a custom theme, at least for the landing page and the logo. After those changes the frontend should be built again.

Follow the same [installation manual](https://wiki.lyrasis.org/display/DSDOC8x/Installing+DSpace).

### Install dependencies (Node.js, Yarn, PM2, etc.)

```bash
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.4/install.sh | bash
# Re-login and install 22.x for DSpace 9.x (no Yarn for 9.x)
nvm install 22
npm install -g pm2
```

### Download and unzip the frontend build:

```bash
cd ~/download
export VERSION=9_2
wget https://github.com/saiful-semantic/DSpace-Binary-Release/releases/download/angular_${VERSION}/angular${VERSION}-dist.zip
mkdir -p ~/frontend/config
cd ~/frontend
unzip ~/download/angular${VERSION}-dist.zip
# It will extract the `dist` folder into ~/frontend/dist
tee config/config.prod.yml > /dev/null <<EOF
# Frontend
ui:
  ssl: false
  host: localhost
  port: 4000
  nameSpace: /

# Backend
rest:
  ssl: false
  host: localhost
  port: 8080
  nameSpace: /server
EOF
```

### Test Run

```bash
cd ~/frontend
node ./dist/server/main.js
```

## Reverse Proxy Using Caddy

>Reverse proxy setup is optional. If you are accessing DSpace from a different machine, you will need to set up a reverse proxy. Otherwise, you can skip this step.

If already have Apache or Nginx, you may configure a new site/VirtualHost as per official documentation. On a fresh machine, Caddy is much easier to configure.

Here's a sample Caddyfile for reverse proxying DSpace backend and frontend:

```bash
# Install Caddy, if not already installed
sudo apt install caddy

# This will replace the existing Caddyfile
sudo tee /etc/caddy/Caddyfile > /dev/null <<EOF
http://ip_address {
    handle /server/* {
        reverse_proxy 127.0.0.1:8080
    }

    handle {
        reverse_proxy localhost:4000
    }
}
EOF

sudo systemctl reload caddy
```

### For automatic HTTPS with Let's Encrypt

For this to work, you need to have a Fully Qualified Domain Name (FQDN) pointing to your server.

```bash
sudo tee /etc/caddy/Caddyfile > /dev/null <<EOF
repository.university.edu {
    handle /server/* {
        reverse_proxy 127.0.0.1:8080 {
            header_up X-Forwarded-Proto https
        }
    }

    handle {
        reverse_proxy localhost:4000
    }
}
EOF

sudo systemctl reload caddy
```

> Caddy will automatically obtain and renew Let's Encrypt certificates. It does not require tools like certbot.

The above configuration will obviously require appropriate `dspace.server.url` and `dspace.ui.url` setting in `[dspace.dir]/config/local.cfg` as well as in the frontend configuration (`~/frontend/config/config.prod.yml`).
