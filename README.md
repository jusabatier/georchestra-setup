# georchestra-setup
Allow to quickly setup an "All in One" Debian Jessie Server for Georchestra

/!\ Not for production use /!\

For production use, I suggest to externalise Database in a dedicated server.

The LDAP/CAS server could also be externalised depends on your needs.

## Setup the server

In order to perform :

- deploy a fresh Debian Jessie VM
- configure a static IP in _/etc/network/interfaces_
- enable root ssh login in _/etc/ssh/sshd_config_ (set PermitRootLogin to yes)
- reboot the server

After that you have to clone this repo :

```
git clone https://github.com/jusabatier/georchestra-setup.git
```

Configure the **install.sh** script to suits your needs.

I recomend to change all passwords variables.
Also if your server have more than one IP adress, you should change the SERVER_IP to the one you want to use for georchestra.

You're ready to launch the install with the root user : 

```
# ./install.sh
```

When the script end, you'll have a server ready to host a georchestra instance.

## What is done ?

Let see what we installed : 

- DBinstall.sh :

It installs the Postgresql/Postgis database and configure it to accept remote connections.
It also constucts the georchestra's database for every modules.

- LDAPinstall.sh :

It installs the LDAP service and create the georchestra's users and groups.

- PROXYinstall.sh :

It installs the Nginx proxy and php5.

After what the georchestra website structure will be created.

It also generate the Nginx's conf files for georchestra and a self-signed SSL certificate.

- TOMCATinstall.sh : 

It wil be successively called by install.sh in order to generate all the differents tomcats.

```
Proxy => Tomcat 6 (listen: 8080, stop: 8005)
CAS => Tomcat 7 (listen: 8081, stop: 8015)
Mapfish => Tomcat 7 (listen: 8082, stop: 8025)
Extractor => Tomcat 7 (listen: 8083, stop: 8035)
GeoNetwork => Tomcat 6 (listen: 8084, stop: 8045)
Utils (analytics,catalogapp,downloadform,geofence,header,ldapadmin) => Tomcat 7 (listen: 8085, stop: 8055)
GeoServer (+GWC) => Tomcat 7 (listen: 8086, stop: 8065)
```

It will also configure the JAVA_OPTS for every tomcat instance.

Install.sh creates the modules datadirs : 

- /var/sig/tmp_extracts for Extractor
- /var/sig/geonetwork_datadir for GeoNetwork
- /var/sig/geoserver_datadir for GeoServer
- /var/sig/geowebcache_cachedir for GWC
