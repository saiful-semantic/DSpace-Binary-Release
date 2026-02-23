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

**Solr 9.x Installation:**

```bash
cd /tmp
wget https://www.apache.org/dyn/closer.lua/solr/solr/9.10.1/solr-9.10.1.tgz?action=download -O solr-9.10.1.tgz
tar xzf solr-9.10.1.tgz solr-9.10.1/bin/install_solr_service.sh --strip-components=2
sudo bash ./install_solr_service.sh solr-9.10.1.tgz
```

> It will install Solr binaries and libraries into `/opt/solr` directory and data into `/var/solr/data` directory.

**Solr 9.x Configuration:**

Edit `/etc/default/solr.in.sh` and add the following:

```bash
SOLR_OPTS="$SOLR_OPTS -Dsolr.config.lib.enabled=true -Djava.security.manager=allow"
```

**Set resource limits for Solr:**

```bash
printf "solr hard nofile 65535\nsolr soft nofile 65535\nsolr hard nproc 65535\nsolr soft nproc 65535\n" | sudo tee /etc/security/limits.d/solr.conf > /dev/null
```

**Enable and start Solr:**

```bash
sudo systemctl start solr
sudo systemctl enable solr
```

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

### Configure Solr Cores

Copy Solr cores from `[dspace.dir]/solr` into Solr data directory:

```bash
cp -r [dspace.dir]/solr/* /var/solr/data/
sudo chown -R solr:solr /var/solr/data/
sudo systemctl restart solr
```

### Test the backend with embedded Tomcat

```bash
java -Ddspace.dir=[dspace.dir] -Dlogging.config=[dspace.dir]/config/log4j2.xml -jar [dspace.dir]/server-boot.jar
```

If there are no errors, you can access the backend at:
http://localhost:8080/server/ or `http://[IP_ADDRESS]:8080`

### Use `systemd` to run the backend in production

Create `/etc/dspace/dspace.env` and add the following (assuming backend is installed at `/home/dspace/backend`):

```bash
DSPACE_DIR=/home/dspace/backend
LOGGING_CONFIG=/home/dspace/backend/config/log4j2.xml
SERVER_PORT=8080
JAVA_OPTS="-Xms512m -Xmx1g -XX:+UseG1GC"
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

- Look for clues in `[dspace.dir]/logs/dspace.log` and `/var/solr/logs/solr.log`
- Check if the database is running and accessible
- Check if the solr server is running and accessible

## How to Use the Frontend Build

**THIS IS NOT FOR PRODUCTION**

This step is only for quick testing, to check if backend is working as expected. In production, the UI will need to be customized with a custom theme, at least for the landing page and the logo. After those changes the frontend should be built again.

Follow the official [installation manual](https://wiki.lyrasis.org/display/DSDOC9x/Installing+DSpace#InstallingDSpace-InstallingtheFrontend(UserInterface)) for more details.

### Install NodeJs using Node Version Manager (NVM)

```bash
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.4/install.sh | bash
\. "$HOME/.nvm/nvm.sh"
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

> **Note:** If you are running this on a VM or a remote machine, replace `localhost` with the IP address or the domain name of that machine.

> **Important:** If the host is changed above, the same host IP/domain name must be updated in the `config/local.cfg` in `dspace.server.url` and `dspace.ui.url` accordingly and backend service restarted.

### Test Run

```bash
cd ~/frontend
node ./dist/server/main.js
```

If there are no errors, you can now access the frontend at: http://localhost:4000 or `http://[IP_ADDRESS]:4000`

### Running the Angular frontend with `pm2` and `systemd`

Install `pm2`:

```bash
npm install -g pm2
```

Create a PM2 service file `~/frontend/app.json` and add the following:

```json
{
    "apps": [
        {
            "name": "dspace-ui",
            "cwd": "/home/dspace/frontend",
            "script": "dist/server/main.js",
            "instances": "2",
            "exec_mode": "cluster",
            "autorestart": true,
            "watch": false,
            "max_memory_restart": "1G",
            "env": {
                "NODE_ENV": "production"
            }
        }
    ]
}
```

Start the service:

```bash
pm2 start ~/frontend/app.json
pm2 save
```

Now the Angular frontend service will start automatically during boot. You can check the status of the service by running `pm2 list`.

Add this line in the `crontab` to restart the service automatically during boot:

```bash
@reboot pm2 resurrect
```

> **Note:** Refer to this [documentation](https://pm2.keymetrics.io/docs/usage/startup/) for more strategies to manage the `pm2` service.

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
