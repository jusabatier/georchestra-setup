#!/bin/bash

if [ $CUSTOMCAT_VERSION -eq 6 ]; then
	tar -xzf /tmp/tomcat-6.tar.gz -C /opt
	mv /opt/apache-tomcat-6.0.43 /opt/tomcat-$CUSTOMCAT_NAME
elif [ $CUSTOMCAT_VERSION -eq 7 ]; then
	tar -xzf /tmp/tomcat-7.tar.gz -C /opt
	mv /opt/apache-tomcat-7.0.57 /opt/tomcat-$CUSTOMCAT_NAME
fi

rm -rf /opt/tomcat-$CUSTOMCAT_NAME/webapps/*
mkdir /opt/tomcat-$CUSTOMCAT_NAME/.java
cp /opt/tomcat-$CUSTOMCAT_NAME/bin/catalina.sh /opt/tomcat-$CUSTOMCAT_NAME/bin/catalina.sh.bak

if [ $CUSTOMCAT_VERSION -eq 6 ]; then
	sed '24 c\CATALINA_HOME="/opt/tomcat-'"$CUSTOMCAT_NAME"'"' /opt/tomcat-$CUSTOMCAT_NAME/bin/catalina.sh.bak | 
	sed '42 c\JAVA_HOME="/usr/lib/jvm/java-7-openjdk-amd64"' |
	sed '48 c\JAVA_OPTS="'"$CUSTOMCAT_JAVAOPTS"'"' > /opt/tomcat-$CUSTOMCAT_NAME/bin/catalina.sh
elif [ $CUSTOMCAT_VERSION -eq 7 ]; then
	sed '27 c\CATALINA_HOME="/opt/tomcat-'"$CUSTOMCAT_NAME"'"' /opt/tomcat-$CUSTOMCAT_NAME/bin/catalina.sh.bak | 
	sed '49 c\JAVA_HOME="/usr/lib/jvm/java-7-openjdk-amd64"' |
	sed '60 c\JAVA_OPTS="'"$CUSTOMCAT_JAVAOPTS"'"' > /opt/tomcat-$CUSTOMCAT_NAME/bin/catalina.sh
fi

rm /opt/tomcat-$CUSTOMCAT_NAME/bin/catalina.sh.bak

sed -i -e "s/<Server port=\"8005\" shutdown=\"SHUTDOWN\">/<Server port=\"$CUSTOMCAT_STOP\" shutdown=\"SHUTDOWN\">/g" /opt/tomcat-$CUSTOMCAT_NAME/conf/server.xml
sed -i -e "s/<Connector port=\"8080\" protocol=\"HTTP\/1.1\"/<Connector port=\"$CUSTOMCAT_PORT\" protocol=\"HTTP\/1.1\"/g" /opt/tomcat-$CUSTOMCAT_NAME/conf/server.xml
sed -i -e "s/<Connector port=\"8009\" protocol=\"AJP\/1.3\" redirectPort=\"8443\" \/>/<!--<Connector port=\"8009\" protocol=\"AJP\/1.3\" redirectPort=\"8443\" \/>-->/g" /opt/tomcat-$CUSTOMCAT_NAME/conf/server.xml

chown -R tomcat:tomcat /opt/tomcat-$CUSTOMCAT_NAME

cat <<EOT >> /etc/init.d/georchestra-$CUSTOMCAT_NAME
#!/bin/bash

### BEGIN INIT INFO
# Provides:          /etc/init.d/georchestra-$CUSTOMCAT_NAME
# Required-Start:    \$remote_fs $syslog
# Required-Stop:     \$remote_fs $syslog
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Short-Description: Start daemon at boot time
# Description:       Enable service provided by daemon.
### END INIT INFO

START_TOMCAT=/opt/tomcat-$CUSTOMCAT_NAME/bin/startup.sh
STOP_TOMCAT=/opt/tomcat-$CUSTOMCAT_NAME/bin/shutdown.sh
PROG="georchestra-$CUSTOMCAT_NAME"

start(){
     echo -n "Starting \$PROG: "
	#Demarrer avec lutilisateur tomcat
     su -p -s /bin/sh tomcat \${START_TOMCAT}
     echo "done."
}

stop(){
     echo -n "Shutting down \$PROG: "
     su -p -s /bin/sh tomcat \${STOP_TOMCAT}
     echo "done."
}

restart(){
   stop
   sleep 50
   start
}

reload(){
   restart
}

case "\$1" in
  start)
      start
      ;;
  stop)
      stop
      ;;
  restart)
      restart
      ;;
  reload)
      reload
      ;;
  *)
      echo "Usage : \$0 {start|stop|restart|reload}"
esac

exit 0
EOT

chmod 744 /etc/init.d/georchestra-$CUSTOMCAT_NAME
chkconfig --add georchestra-$CUSTOMCAT_NAME
