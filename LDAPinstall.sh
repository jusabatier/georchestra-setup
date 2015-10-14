#!/bin/bash

debconf-set-selections <<< "slapd slapd/password1 password $LDAP_PASSWORD"
debconf-set-selections <<< "slapd slapd/password2 password $LDAP_PASSWORD"
debconf-set-selections <<< "slapd slapd/backend select MDB"
apt-get -y install slapd ldap-utils

service slapd stop
if [ -f /etc/ldap/slapd.d/cn\=config/olcDatabase\=\{1\}mdb.ldif ] ; then
	rm /etc/ldap/slapd.d/cn\=config/olcDatabase\=\{1\}mdb.ldif
fi
rm /var/lib/ldap/*
service slapd start

wget https://raw.githubusercontent.com/georchestra/LDAP/$GEORCHESTRA_VERSION/georchestra-bootstrap.ldif -O /tmp/bootstrap.ldif
sed -i -e "s/secret/$LDAP_PASSWORD/g" /tmp/bootstrap.ldif
ldapadd -Y EXTERNAL -H ldapi:/// -f /tmp/bootstrap.ldif

wget https://raw.githubusercontent.com/georchestra/LDAP/$GEORCHESTRA_VERSION/georchestra-memberof.ldif -O /tmp/memberof.ldif
ldapadd -Y EXTERNAL -H ldapi:/// -f /tmp/memberof.ldif 

wget https://raw.githubusercontent.com/georchestra/LDAP/$GEORCHESTRA_VERSION/georchestra-root.ldif -O /tmp/root.ldif
ldapadd -D"cn=admin,dc=georchestra,dc=org" -w $LDAP_PASSWORD -f /tmp/root.ldif

wget https://raw.githubusercontent.com/georchestra/LDAP/$GEORCHESTRA_VERSION/georchestra.ldif -O /tmp/georchestra.ldif
ldapadd -D"cn=admin,dc=georchestra,dc=org" -w $LDAP_PASSWORD -f /tmp/georchestra.ldif
