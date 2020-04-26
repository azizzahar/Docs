


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
apt-get -y update &&
apt-get install jitsi-meet -y &&
apt-get install jitsi-meet-tokens -y
```

# Open necessary ports

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
ufw allow in 5347/tcp &&
ufw allow in 10000:20000/udp
```

# Jitsi meet tokens final changes

Open file `/etc/prosody/config.avail/<host>.cfg.lua` and check if first line is `--plugin_paths =`
and check if config file not updated to authentication = "token", do those edits then run
```bash
sed -i 's/module:hook/module:hook_global/g' /usr/share/jitsi-meet/prosody-plugins/mod_auth_token.lua
```


# Config prosody

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

## Setup issuers and audiences 

Open `/etc/prosody/conf.avail/<host>.cfg.lua`

and add above lines with your issuers and audiences

```
asap_accepted_issuers = { "jitsi", "smash" }
asap_accepted_audiences = { "jitsi", "smash" }
```

Under you domain config change authentication to "token" and provide application ID, secret and optionally token lifetime:

```
VirtualHost "jitmeet.example.com"
    authentication = "token";
    app_id = "example_app_id";             -- application identifier
    app_secret = "example_app_secret";     -- application secret known only to your token
```

To access the data in lib-jitsi-meet you have to enable the prosody module mod_presence_identity in your config.

```
VirtualHost "jitmeet.example.com"
    modules_enabled = { "presence_identity" }
```

Enable room name token verification plugin in your MUC component config section:

```
Component "conference.jitmeet.example.com" "muc"
    modules_enabled = { "token_verification" }
```

Setup guest domain
```
VirtualHost "guest.jitmeet.example.com"
    authentication = "token";
    app_id = "example_app_id";
    app_secret = "example_app_secret";
    c2s_require_encryption = true;
    allow_empty_token = true;
```

Edit jicofo sip-communicator in `/etc/jitsi/jicofo/sip-communicator.properties`
```
org.jitsi.jicofo.auth.URL=XMPP:jitmeet.example.com
org.jitsi.jicofo.auth.DISABLE_AUTOLOGIN=true
```

Edit jicofo config in `/etc/jitsi/jicofo/config`
SET the follow configs
```
JICOFO_HOST=jitmeet.example.com
```

And edit videobridge config in `/etc/jitsi/videobridge/config`

Replace 
```
JVB_HOSTNAME=localhost
```
TO
```
JVB_HOSTNAME=jitmeet.example.com
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


# Helpers

Restart all services
```bash
systemctl restart prosody jicofo jitsi-videobridge2
```

Prosody logs
```bash
tail -f -n 350 /var/log/prosody/prosody.log
```

Jicofo logs
```bash
tail -f -n 350 /var/log/jitsi/jicofo.log
```

JVB logs
```bash
tail -f -n 350 /var/log/jitsi/jvb.log
```