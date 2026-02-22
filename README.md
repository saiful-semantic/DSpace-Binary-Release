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

This repository contains binary releases of vanilla DSpace Backend and Frontend (Angular UI) components.

## How to Use the Backend Build

Follow the instruction in the [installation manual](https://wiki.lyrasis.org/display/DSDOC9x/Installing+DSpace) for the specific release for more details.

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
mkdir ~/download
cd ~/download
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

Create `/etc/dspace/dspace.env` and add the following (assuming backend is installed at `/home/dspace/backend`):

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

Follow the official [installation manual](https://wiki.lyrasis.org/display/DSDOC9x/Installing+DSpace#InstallingDSpace-InstallingtheFrontend(UserInterface)) for more details.

### Install NodeJs using Node Version Manager (NVM)

```bash
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.4/install.sh | bash
```

**Re-login to the terminal and install required node version:**
```bash
nvm install 22
```

### Download and unzip the frontend build:

```bash
cd ~/download
export VERSION=9_2
wget https://github.com/saiful-semantic/DSpace-Binary-Release/releases/download/angular_${VERSION}/angular${VERSION}-dist.zip
mkdir -p ~/frontend/config
cd ~/frontend
unzip ~/download/angular${VERSION}-dist.zip
```
> The above commands will extract the `dist` folder into `~/frontend/dist` folder.

Create `config/config.prod.yml` and add the following:    

```yaml
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
```

### Test Run

```bash
cd ~/frontend
node ./dist/server/main.js
```

> Production deployment will use tools like `pm2` or `systemd` to manage the lifecycle of the frontend server. Refer to the official documentation for more information.

## Reverse Proxy Using Caddy

>Reverse proxy setup is optional. If you are accessing DSpace from a different machine, you will need to set up a reverse proxy. Otherwise, you can skip this step.

If you already have Apache or Nginx installed, you may configure a new site/VirtualHost as per official documentation. However, on a fresh machine, Caddy is much easier to configure.

**Install Caddy, if not already installed:**

```bash
sudo apt install caddy
```

**Edit `/etc/caddy/Caddyfile` and add the following for local testing (non-SSL):**

```caddy
http://[IP_ADDRESS] {
    handle /server/* {
        reverse_proxy 127.0.0.1:8080
    }

    handle {
        reverse_proxy localhost:4000
    }
}
```

**Reload Caddy:**

```bash
sudo systemctl reload caddy
```

### For automatic HTTPS with Let's Encrypt (SSL)

For this to work, you need to have a Fully Qualified Domain Name (FQDN) or a domain name pointing to your server. Here is a working example for `repository.university.edu`:

```caddy
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
```

> **Note:** Caddy will automatically obtain and renew Let's Encrypt certificates. It does not require tools like `certbot`.

The above configuration will obviously require appropriate `dspace.server.url` and `dspace.ui.url` setting in `[dspace.dir]/config/local.cfg` as well as in the frontend configuration (`~/frontend/config/config.prod.yml`).
