#!/bin/bash

#########################################################################
#
# Configurations
#
#########################################################################
SERVER_IP=$(hostname -I)
SERVER_NAME="vm-jessie"

GEORCHESTRA_VERSION="15.06"

POSTGRES_VERSION="9.4"
POSTGIS_VERSION="2.1"
POSTGRES_PASSWORD="pgpass"

LDAP_PASSWORD="ldappass"

SSL_PASSPHRASE="siglepuy"
SSL_COUNTRY="FR"
SSL_STATE="Auvergne"
SSL_LOCALITY="Le Puy-en-Velay"
SSL_ORGANISATION="Communauté d'agglomeration"
SSL_UNIT="Service SIG"

_script="$(readlink -f ${BASH_SOURCE[0]})"
_base="$(dirname $_script)"

#########################################################################
#
# Installation paquets utilitaires
#
#########################################################################
apt-get -y install git chkconfig sudo

#########################################################################
#
# Installation Base de données
#
#########################################################################
. ./DBinstall.sh

#########################################################################
#
# Installation LDAP
#
#########################################################################
. ./LDAPinstall.sh

#########################################################################
#
# Installation Proxy http
#
#########################################################################
. ./PROXYinstall.sh

#########################################################################
#
# Installation Tomcat
#
#########################################################################
apt-get -y install openjdk-7-jdk libtcnative-1

groupadd tomcat
useradd -g tomcat -s /usr/sbin/nologin -m -d /home/tomcat tomcat

# wget http://apache.mirrors.ovh.net/ftp.apache.org/dist/tomcat/tomcat-8/v8.0.27/bin/apache-tomcat-8.0.27.tar.gz /tmp/tomcat-8.tar.gz
cp $_base/tomcat-dist/apache-tomcat-8.0.27.tar.gz  /tmp/tomcat-8.tar.gz

mkdir /var/sig
mkdir /var/sig/tmp_extracts
git clone https://github.com/georchestra/geonetwork_minimal_datadir.git /var/sig/geonetwork_datadir
git clone https://github.com/georchestra/geoserver_minimal_datadir.git /var/sig/geoserver_datadir
mkdir /var/sig/geowebcache_cachedir


chown -R tomcat:tomcat /var/sig

CUSTOMCAT_VERSION=8
CUSTOMCAT_NAME="proxy"
CUSTOMCAT_PORT=8080
CUSTOMCAT_STOP=8005
CUSTOMCAT_JAVAOPTS="-Djava.awt.headless=true -XX:+UseConcMarkSweepGC -Xms256m -Xmx256m -XX:MaxPermSize=128m"
. ./TOMCATinstall.sh

CUSTOMCAT_VERSION=8
CUSTOMCAT_NAME="cas"
CUSTOMCAT_PORT=8081
CUSTOMCAT_STOP=8015
. ./TOMCATinstall.sh

CUSTOMCAT_VERSION=8
CUSTOMCAT_NAME="mapfish"
CUSTOMCAT_PORT=8082
CUSTOMCAT_STOP=8025
CUSTOMCAT_JAVAOPTS="-Djava.awt.headless=true -XX:+UseConcMarkSweepGC -Xms2G -Xmx2G -XX:MaxPermSize=256m"
. ./TOMCATinstall.sh

CUSTOMCAT_VERSION=8
CUSTOMCAT_NAME="extractor"
CUSTOMCAT_PORT=8083
CUSTOMCAT_STOP=8035
CUSTOMCAT_JAVAOPTS="-Djava.awt.headless=true -XX:+UseConcMarkSweepGC -Xms2G -Xmx2G -XX:MaxPermSize=256m -Dorg.geotools.referencing.forceXY=true -Dextractor.storage.dir=/var/sig/tmp_extracts -Djava.util.prefs.userRoot=/tmp -Djava.util.prefs.systemRoot=/tmp"
. ./TOMCATinstall.sh

CUSTOMCAT_VERSION=8
CUSTOMCAT_NAME="geonetwork"
CUSTOMCAT_PORT=8084
CUSTOMCAT_STOP=8045
CUSTOMCAT_JAVAOPTS="-Djava.awt.headless=true -XX:+UseConcMarkSweepGC -Xms2G -Xmx2G -XX:MaxPermSize=256m -Dgeonetwork.dir=/var/sig/geonetwork_datadir -Dgeonetwork.schema.dir=/var/sig/config/schema_plugins -Dgeonetwork.jeeves.configuration.overrides.file=/opt/tomcat-$CUSTOMCAT_NAME/webapps/geonetwork/WEB-INF/config-overrides-georchestra.xml -Djava.util.prefs.userRoot=/tmp -Djava.util.prefs.systemRoot=/tmp"
. ./TOMCATinstall.sh

CUSTOMCAT_VERSION=8
CUSTOMCAT_NAME="utils"
CUSTOMCAT_PORT=8085
CUSTOMCAT_STOP=8055
CUSTOMCAT_JAVAOPTS="-Djava.awt.headless=true -XX:+UseConcMarkSweepGC -Xms2G -Xmx2G -XX:MaxPermSize=256m"
. ./TOMCATinstall.sh

CUSTOMCAT_VERSION=8
CUSTOMCAT_NAME="geoserver"
CUSTOMCAT_PORT=8086
CUSTOMCAT_STOP=8065
CUSTOMCAT_JAVAOPTS="-Djava.awt.headless=true -XX:+UseConcMarkSweepGC -Xms2G -Xmx2G -XX:PermSize=256m -XX:MaxPermSize=256m -DGEOSERVER_DATA_DIR=/var/sig/geoserver_datadir -DGEOWEBCACHE_CACHE_DIR=/var/sig/geowebcache_cachedir -Dfile.encoding=UTF8 -Djavax.servlet.request.encoding=UTF-8 -Djavax.servlet.response.encoding=UTF-8 -server -XX:+UseParNewGC -XX:ParallelGCThreads=2 -XX:SoftRefLRUPolicyMSPerMB=36000 -XX:NewRatio=2 -XX:+AggressiveOpts -Djava.library.path=/usr/lib/jni:/opt/libjpeg-turbo/lib64"
. ./TOMCATinstall.sh
sed -i -e "s/<Connector port=\"$CUSTOMCAT_PORT\" protocol=\"HTTP\/1.1\"/<Connector port=\"$CUSTOMCAT_PORT\" protocol=\"HTTP\/1.1\" URIEncoding=\"UTF-8\" maxThreads=\"20\" minSpareThreads=\"20\"/g" /opt/tomcat-$CUSTOMCAT_NAME/conf/server.xml

apt-get install -y libgdal1h libgdal-java gdal-bin

sed -i -e "s/deb http:\/\/ftp.fr.debian.org\/debian\/ jessie main/deb http:\/\/ftp.fr.debian.org\/debian\/ jessie main contrib non-free/g" /etc/apt/sources.list
sed -i -e "s/deb http:\/\/security.debian.org\/ jessie\/updates main/deb http:\/\/security.debian.org\/ jessie\/updates main contrib non-free/g" /etc/apt/sources.list
apt-get update

apt-get install -y libjai-core-java libjai-imageio-core-java
ln -s /usr/share/java/clibwrapper_jiio.jar /opt/tomcat-$CUSTOMCAT_NAME/lib/clibwrapper_jiio.jar
ln -s /usr/share/java/jai_codec.jar /opt/tomcat-$CUSTOMCAT_NAME/lib/jai_codec.jar
ln -s /usr/share/java/jai_core.jar /opt/tomcat-$CUSTOMCAT_NAME/lib/jai_core.jar
ln -s /usr/share/java/jai_imageio.jar /opt/tomcat-$CUSTOMCAT_NAME/lib/jai_imageio.jar
ln -s /usr/share/java/mlibwrapper_jai.jar /opt/tomcat-$CUSTOMCAT_NAME/lib/mlibwrapper_jai.jar

apt-get install -y ttf-mscorefonts-installer

wget http://downloads.sourceforge.net/project/libjpeg-turbo/1.4.0/libjpeg-turbo-official_1.4.0_amd64.deb -O /tmp/libjpeg-turbo-official_1.4.0_amd64.deb
dpkg -i /tmp/libjpeg-turbo-official_1.4.0_amd64.deb
