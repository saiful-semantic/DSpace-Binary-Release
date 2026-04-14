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

This repository contains pre-built binary releases of vanilla DSpace Backend and Frontend (Angular UI) components.

# How to Use the Backend Build

Following are the steps to install and configure the DSpace 9.2 backend build in Ubuntu 24.04 LTS or equivalent Linux distributions.

> Always refer to the official instruction in the [installation manual](https://wiki.lyrasis.org/display/DSDOC9x/Installing+DSpace) for the specific release for any additional information.

## Create DSpace User and Switch to it

```bash
sudo adduser dspace

# Sudo access is required at least during the installation process
sudo usermod -aG sudo dspace

# Switch to the app user
sudo su - dspace
```

## Install Dependencies (JDK, PostgreSQL, Solr, etc.)

```bash
sudo apt update
sudo apt install openjdk-17-jdk-headless ant postgresql zip curl
```

> [!NOTE]
>
> The `openjdk-17-jdk-headless` is a server-optimized JDK without GUI.
>
> Ubuntu 24.04 LTS comes with PostgreSQL 16, which has the `pgcrypto` extension enabled by default.
>
> For older versions of PostgreSQL (13 or older), the `postgresql-contrib` package must also be installed to enable the `pgcrypto` extension.

### Apache Solr 9.x Installation

```bash
cd /tmp
wget https://www.apache.org/dyn/closer.lua/solr/solr/9.10.1/solr-9.10.1.tgz?action=download -O solr-9.10.1.tgz
tar xzf solr-9.10.1.tgz solr-9.10.1/bin/install_solr_service.sh --strip-components=2
sudo bash ./install_solr_service.sh solr-9.10.1.tgz
```

The above commands will install Apache Solr binaries and libraries into `/opt/solr` directory and data into `/var/solr/data` directory.

### Apache Solr 9.x Configuration

Edit `/etc/default/solr.in.sh` and add the following:

```bash
SOLR_OPTS="$SOLR_OPTS -Dsolr.config.lib.enabled=true -Djava.security.manager=allow"
```

### Set resource limits for Solr

```bash
printf "solr hard nofile 65535\nsolr soft nofile 65535\nsolr hard nproc 65535\nsolr soft nproc 65535\n" | sudo tee /etc/security/limits.d/solr.conf > /dev/null
```

### Enable and start Solr

```bash
sudo systemctl start solr
sudo systemctl enable solr
```

## Create database user, database, enable pgcrypto

```bash
sudo -u postgres psql -c "CREATE USER dspace WITH PASSWORD 'strongPassword' CREATEDB;"
sudo -u postgres createdb --owner=dspace --encoding=UTF8 dspace
sudo -u postgres psql -d dspace -c "CREATE EXTENSION pgcrypto;"
```

## Download and Unzip the Backend Build

```bash
cd /tmp
export VERSION=9_2
wget https://github.com/saiful-semantic/DSpace-Binary-Release/releases/download/backend_${VERSION}/dspace${VERSION}-installer.zip
unzip dspace${VERSION}-installer.zip
cd dspace-installer
```

### Update the configuration

```bash
cp config/local.cfg{.EXAMPLE,}
nano config/local.cfg # or vi config/local.cfg
```

> [!IMPORTANT]
> Update these two settings at the minimum:
>
> * `dspace.dir=/home/dspace/backend`
> * `db.password=strongPassword` # Update with your password

### Deploy the build and migrate database

```bash
ant fresh_install
cd /home/dspace/backend
bin/dspace database migrate
bin/dspace database info
``` 

## Configure Solr Cores

Copy Solr cores from `/home/dspace/backend/solr` into Solr data directory:

```bash
sudo cp -r /home/dspace/backend/solr/* /var/solr/data/
sudo chown -R solr:solr /var/solr/data/
sudo systemctl restart solr
```

## Test the backend with embedded Tomcat (DSpace 8.x and above)

```bash
# Pattern: java -Ddspace.dir=[dspace.dir] -Dlogging.config=[dspace.dir]/config/log4j2.xml -jar [dspace.dir]/webapps/server-boot.jar
# For example:
java -Ddspace.dir=/home/dspace/backend -Dlogging.config=/home/dspace/backend/config/log4j2.xml -jar /home/dspace/backend/webapps/server-boot.jar
```

Wait for a minute or two for the first boot to complete.

If there are no errors, you can access the backend at:
http://localhost:8080/server/

### Remote access (for testing)

If you are installing on a remote machine via SSH, use [SSH tunnel](https://goteleport.com/blog/ssh-tunneling-explained/) to access the backend. For example:

```bash
ssh -L 8080:localhost:8080 dspace@remote-server
```

Then access the backend at: http://localhost:8080/server

## Production Deployment of Backend

Create an environment file:

```bash
sudo mkdir /etc/dspace
sudo nano /etc/dspace/dspace.env
```

Copy the following content into the file:

```ini
DSPACE_DIR=/home/dspace/backend
LOGGING_CONFIG=/home/dspace/backend/config/log4j2.xml
SERVER_PORT=8080
JAVA_OPTS="-Xms512m -Xmx1g -XX:+UseG1GC"
```

Edit systemd service file:

```bash
sudo nano /etc/systemd/system/dspace.service
```

Copy the following content into the file:

```ini
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

### Reload and enable the service

```bash
sudo systemctl daemon-reload
sudo systemctl enable dspace
sudo systemctl start dspace
```

### Check the status

```bash
sudo systemctl status dspace
journalctl -u dspace -f
```

### Troubleshooting

- Look for clues in the DSpace or Solr log files:
    - `tail -f /home/dspace/backend/log/dspace.log`
    - `sudo tail -f /var/solr/logs/solr.log`
- Check if the database is running and accessible:
    - `sudo systemctl status postgresql`
- Check if the solr server is running and accessible:
    - `sudo systemctl status solr`

# How to Use the Frontend Build

> [!WARNING]
> **THIS IS NOT FOR PRODUCTION**
>
> This step is only for quick testing, to check if backend is working as expected. In production, the UI will need to be customized with a custom theme, at least for the landing page and the logo. After those changes the frontend should be built again.
>
> Follow the official [installation manual](https://wiki.lyrasis.org/display/DSDOC9x/Installing+DSpace#InstallingDSpace-InstallingtheFrontend(UserInterface)) for more details.

## Install NodeJs from official repository

```bash
sudo apt update
sudo apt install curl
curl -fsSL https://deb.nodesource.com/setup_22.x | sudo -E bash -
sudo apt install -y nodejs
```

## Download and unzip the frontend build

```bash
cd /tmp
export VERSION=9_2
wget https://github.com/saiful-semantic/DSpace-Binary-Release/releases/download/angular_${VERSION}/angular${VERSION}-dist.zip
mkdir -p /home/dspace/frontend/config
cd /home/dspace/frontend
unzip /tmp/angular${VERSION}-dist.zip
```

> The above commands will extract the `dist` folder into `/home/dspace/frontend/dist` folder.

## Create frontend config file

```bash
cd /home/dspace/frontend
nano config/config.prod.yml
```

Add the following content:

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

## Test Run

```bash
cd /home/dspace/frontend
node ./dist/server/main.js
```

If there are no errors, you can now access the frontend at: http://localhost:4000

### Remote access (for testing)

If you are installing on a remote machine via SSH, use [SSH tunnel](https://goteleport.com/blog/ssh-tunneling-explained/) to access the frontend. For example:

```bash
ssh -L 4000:localhost:4000 -L 8080:localhost:8080 dspace@remote-server
```

Then access the frontend at: http://localhost:4000 and backend at: http://localhost:8080/server

> [!IMPORTANT]
>
> Both the endpoints, backend and frontend, must be accessible from the client machine for the frontend to work.

## Production Deployment of Frontend

Install `pm2`:

```bash
sudo npm install -g pm2
```

Create a PM2 service file:

```bash
nano /home/dspace/frontend/app.json
```

Add the following content:

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

### Start the service

```bash
pm2 start /home/dspace/frontend/app.json
pm2 save
pm2 list
```

**Edit the `cron` file to start the service on boot:**

```bash
crontab -e
```

Add the following line to the `cron` file, then save and exit:

```bash
@reboot /usr/bin/pm2 resurrect > /dev/null 2>&1
```

### For Production Deployment of Customized Frontend

1. [Customize the frontend](https://wiki.lyrasis.org/display/DSDOC9x/User+Interface+Customization) to create a theme and update the logo, etc.
2. Prepare the production build using `npm run build:prod`
3. Copy the `dist` folder into `/home/dspace/frontend/dist` folder
4. Restart the frontend service (`pm2 restart all`)

# Production Setup with SSL

> [!IMPORTANT]
> Reverse proxy setup is essential for production.
>
> While the official documentation gives examples of using both Nginx and Apache, Caddy is much easier to configure.

## Install Caddy

```bash
sudo apt install caddy
```

## Reverse Proxy Setup with Caddy

Assuming you have a domain name `repository.university.edu`:

1. Add DNS `A` record for the domain name pointing to your server's IP address.
2. Edit the `Caddyfile`:

```bash
sudo nano /etc/caddy/Caddyfile
```

Add the following content (replace `repository.university.edu` with your domain name):

```Caddyfile
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

> [!NOTE]
> Caddy will automatically obtain and renew Let's Encrypt certificates. It does not require tools like `certbot`.

**Reload Caddy:**

```bash
sudo systemctl reload caddy
```

If the DNS record is correctly set up, it will take less than a minute to get the SSL certificate. For any errors, check the syslog:

```bash
sudo journalctl -u caddy --no-pager -f
# or 
sudo tail -f /var/log/syslog | grep caddy
```

## Update URLs in Backend and Frontend

For the reverse proxy setup, you will need to update the URLs in the frontend configuration and the backend configuration.

### Update backend configuration

```bash
nano /home/dspace/backend/config/local.cfg
```

Edit the following lines:

```bash
dspace.server.url = https://repository.university.edu/server
dspace.ui.url = https://repository.university.edu
```

Restart the backend service:

```bash
sudo systemctl restart dspace
```

### Update frontend configuration

```bash
nano /home/dspace/frontend/config/config.prod.yml
```

Edit only the `rest` section in the file:

```yaml
# Backend
rest:
  ssl: true
  host: repository.university.edu
  port: 443
  nameSpace: /server
```

Restart the frontend service:

```bash
pm2 restart all
```

After reload, you can access the frontend at: `https://repository.university.edu`
