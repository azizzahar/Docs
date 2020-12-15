If you use the prepared images, go directly to [this section](#start-here-if-using-the-prepared-image-and-ignore-the-config-prosody-section)

# Install lua and dependencies

Enter in sudo user

```bash
sudo su
```

Run the follow script to install lua and her dependencies, and prosody with fixes.
After finish, VM will be restarted
```bash
cd &&
apt-get update -y &&
apt-get install apt-transport-https &&
apt-get install software-properties-common -y &&
add-apt-repository universe &&
apt-get update -y &&
apt-get install openjdk-8-jdk -y &&
apt-get install gcc -y &&
apt-get install unzip -y &&
apt-get install lua5.2 -y &&
apt-get install liblua5.2 -y &&
apt-get install luarocks -y &&
luarocks install basexx &&
apt-get install libssl1.0-dev -y &&
luarocks install luacrypto &&
mkdir src &&
cd src &&
luarocks download lua-cjson &&
luarocks unpack lua-cjson-2.1.0.6-1.src.rock &&
cd lua-cjson-2.1.0.6-1/lua-cjson &&
sed -i 's/lua_objlen/lua_rawlen/g' lua_cjson.c &&
sed -i 's|$(PREFIX)/include|/usr/include/lua5.2|g' Makefile &&
luarocks make &&
luarocks install luajwtjitsi &&
cd &&
wget https://prosody.im/files/prosody-debian-packages.key -O- | sudo apt-key add - &&
echo deb http://packages.prosody.im/debian $(lsb_release -sc) main | sudo tee -a /etc/apt/sources.list &&
apt-get update -y &&
apt-get upgrade -y &&
apt-get install prosody -y &&
chown root:prosody /etc/prosody/certs/localhost.key &&
chmod 644 /etc/prosody/certs/localhost.key &&
sleep 2 &&
shutdown -r now
```

# Install jitsi-meet

Enter in sudo user
```bash
sudo su
```

After reboot, run the folow script
```bash
cd &&
cp /etc/prosody/certs/localhost.key /etc/ssl &&
apt-get install nginx -y &&
wget -qO - https://download.jitsi.org/jitsi-key.gpg.key | sudo apt-key add - &&
sh -c "echo 'deb https://download.jitsi.org stable/' > /etc/apt/sources.list.d/jitsi-stable.list" &&
apt-get -y update
```

# Start Here if using the prepared image. Ignore the Config prosody section

Now install Jitsi 
```bash
apt-get install --no-install-recommends jitsi-meet -y &&
apt-get install jitsi-meet-tokens -y
```

# Set up the Fully Qualified Domain Name (FQDN)
If the machine used to host the Jitsi Meet instance has a FQDN (for example meet.example.org) already set up in DNS, you can set it with the following command:
ex: for aquarium.whynotblue.com, SUBDOMAIN = aquarium

```bash
sudo hostnamectl set-hostname SUBDOMAIN
```

Then add the same FQDN in the /etc/hosts file, associating it with the loopback address:
```bash
127.0.0.1 localhost
x.x.x.x SUBDOMAIN.example.org SUBDOMAIN
```
Note: x.x.x.x is your server's public IP address.

Finally on the same machine test that you can ping the FQDN with:
```bash
ping "$(hostname)"
```
If all worked as expected, you should see: SUBDOMAIN.example.com




# Generate a Let's Encrypt certificate
In order to have encrypted communications, you need a TLS certificate. The easiest way is to use Let's Encrypt.

Note: Jitsi Meet mobile apps require a valid certificate signed by a trusted Certificate Authority (such as a Let's Encrypt certificate) and will not be able to connect to your server if you choose a self-signed certificate.

Simply run the following in your shell:

```bash
/usr/share/jitsi-meet/scripts/install-letsencrypt-cert.sh
```

Note that this script uses the HTTP-01 challenge type and thus your instance needs to be accessible from the public internet. If you want to use a different challenge type, don't use this script and instead choose I want to use my own certificate during jitsi-meet installation.

# Open necessary ports (optional)

Enable ufw 
```bash
ufw enable
```

Open ports
```bash
ufw allow in 22/tcp &&
ufw allow in openssh &&
ufw allow in 80/tcp &&
ufw allow in 443/tcp &&
ufw allow in 4443/tcp &&
ufw allow in 5222/tcp &&
ufw allow in 5347/tcp &&
ufw allow in 5349/tcp &&
ufw allow in 10000:20000/udp
```

Check the firewall status with:
```bash
ufw status verbose
```

# Config prosody (ignore if using prepared image)

Open `/etc/prosody/prosody.cfg.lua` and

Add above lines after admins object
```
admins = {}

component_ports = { 5347 }
component_interface = "0.0.0.0"
```
 
 change 
```
c2s_require_encryption=true
```
to
```
c2s_require_encryption=false
```

and check if on end of file has
```
Include "conf.d/*.cfg.lua"
```

# Prosody manual plugin configuration

### Setup issuers and audiences (not needed? works without)

Open `/etc/prosody/conf.avail/<host>.cfg.lua`

and add above lines with your issuers and audiences

```
asap_accepted_issuers = { "jitsi", "smash" }
asap_accepted_audiences = { "jitsi", "smash" }
```

### Under you domain config change authentication to "token" and provide application ID, secret and optionally token lifetime (made automaticaly by jitsi-meet-token installation):

```
VirtualHost "jitmeet.example.com"
    authentication = "token";
    app_id = "example_app_id";             -- application identifier
    app_secret = "example_app_secret";     -- application secret known only to your token
```

### To access the data in lib-jitsi-meet you have to enable the prosody module mod_presence_identity in your config.

```
VirtualHost "jitmeet.example.com"
    modules_enabled = { "presence_identity" }
```

### Enable room name token verification plugin in your MUC component config section (made automaticaly by jitsi-meet-token installation):

```
Component "conference.jitmeet.example.com" "muc"
    modules_enabled = { "token_verification" }
```

### Setup guest domain (optional)
```
VirtualHost "guest.jitmeet.example.com"
    authentication = "token";
    app_id = "example_app_id";
    app_secret = "example_app_secret";
    c2s_require_encryption = true;
    allow_empty_token = true;
```

### Enable guest domain in config.js
Open your meet config in `/etc/jitsi/meet/<host>-config.js` and enable
```js
var config = {
    hosts: {
        ... 
        // When using authentication, domain for guest users.
        anonymousdomain: 'guest.jitmeet.example.com',
        ...
    },
    ...
    enableUserRolesBasedOnToken: true,
    ...
}
```

### Edit jicofo sip-communicator in `/etc/jitsi/jicofo/sip-communicator.properties`
```
org.jitsi.jicofo.auth.URL=XMPP:jitmeet.example.com
org.jitsi.jicofo.auth.URL=XMPP:YOUR_DOMAIN
org.jitsi.jicofo.auth.DISABLE_AUTOLOGIN=true
```

### Edit jicofo config in `/etc/jitsi/jicofo/config`
SET the follow configs
```
JICOFO_HOST=jitmeet.example.com
```

### (NAT) Edit videobridge sip-communicator in `/etc/jitsi/videobridge/sip-communicator.properties`
Add the following lines with correct IPs
```
org.ice4j.ice.harvest.NAT_HARVESTER_LOCAL_ADDRESS=<Local.IP.Address>
org.ice4j.ice.harvest.NAT_HARVESTER_PUBLIC_ADDRESS=<Public.IP.Address>
```
And comment the line that starts with "org.ice4j.ice.harvest.STUN_MAPPING_HARVESTER_ADDRESSES..."

### And edit videobridge config in `/etc/jitsi/videobridge/config`

Replace 
```
JVB_HOST=
```
TO
```
JVB_HOST=jitmeet.example.com
```

And add after `JAVA_SYS_PROPS`
```
JAVA_SYS_PROPS=...
AUTHBIND=yes
```

Then, restart all services
```bash
systemctl restart nginx prosody jicofo jitsi-videobridge2
```

# Setup and configure your firewall (should be done with Google Cloud's "jitsi-server" firewall rule)
The following ports need to be open in your firewall, to allow traffic to the Jitsi Meet server:

- 80 TCP - for SSL certificate verification / renewal with Let's Encrypt
- 443 TCP - for general access to Jitsi Meet
- 10000 UDP - for general network video/audio communications
- 22 TCP - if you access you server using SSH (change the port accordingly if it's not 22)
- 3478 UDP - for quering the stun server (coturn, optional, needs config.js change to enable it)
- 5349 TCP - for fallback network video/audio communications over TCP (when UDP is blocked for example), served by coturn
- 5347 TCP


# Now stop and test. Don't forget the jwt token in the url 


# Token moderation installation
Based on this prosody plugin https://github.com/nvonahsen/jitsi-token-moderation-plugin

- Download this file https://github.com/azizzahar/Docs/blob/master/jitsi-files/mod_token_moderation.lua
- Create a folder in /etc/prosody so the plugin doesn't get deleted
```bash
sudo mkdir /etc/prosody/plugins
```
- Copy the mod_token_moderation.lua file in that folder

## Edit the prosody configuration /etc/prosody/conf.d/[YOUR DOMAIN].cfg.lua
Add the newly created folder prosody plugins
```bash
plugin_paths = { "/usr/share/jitsi-meet/prosody-plugins/", "/etc/prosody/plugins" }
```
Edit the conferance.[YOUR DOMAIN] component to add token_moderation
```bash
modules_enabled = {
        [...]
        "token_moderation";
    }
```
Restart the services
```bash
systemctl restart prosody jicofo jitsi-videobridge2 jigasi
```


# Helpers

Restart all services
```bash
systemctl restart prosody jicofo jitsi-videobridge2 jigasi
```

Prosody logs
```bash
tail -f -n 350 /var/log/prosody/prosody.log
```

Jicofo logs
```bash
tail -f -n 350 /var/log/jitsi/jicofo.log
```

Jigasi logs
```bash
tail -f -n 350 /var/log/jitsi/jigasi.log
```

JVB logs
```bash
tail -f -n 350 /var/log/jitsi/jvb.log
```

Register Jibri
```
prosodyctl register <USER> auth.<DOMAIN> <PASSWORD>
```



# Manual react-jitsi-meet

## Install NodeJS

```bash
curl -sL https://deb.nodesource.com/setup_12.x | sudo bash - &&
apt-get install nodejs -y
```

Clone your repository,

after clone run 
```bash
sudo npm i &&
make
```

After installation, setup Nginx in `/etc/nginx/sites-available/<host>.conf`

```bash
server {
    ...
    location ^~ /.well-known/acme-challenge/ {
        root         /app/jitsi-meet;
    }
    ....
}

server {
    ...
    root /app/jitsi-meet;
    ...
    location ~ ^/(libs|css|static|images|fonts|lang|sounds|connection_optimization|.well-known)/(.*)$
    {
        add_header 'Access-Control-Allow-Origin' '*';
        alias /app/jitsi-meet/$1/$2;
    }
    ...
}
```
