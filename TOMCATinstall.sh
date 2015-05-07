#!/bin/bash

if [ $CUSTOMCAT_VERSION -eq 6 ]; then
	tar -xzf /tmp/tomcat-6.tar.gz -C /opt
	mv /opt/apache-tomcat-6.* /opt/tomcat-$CUSTOMCAT_NAME
elif [ $CUSTOMCAT_VERSION -eq 7 ]; then
	tar -xzf /tmp/tomcat-7.tar.gz -C /opt
	mv /opt/apache-tomcat-7.* /opt/tomcat-$CUSTOMCAT_NAME
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

wget https://jdbc.postgresql.org/download/postgresql-9.4-1201.jdbc41.jar -O /opt/tomcat-$CUSTOMCAT_NAME/lib/postgresql-9.4-1201.jdbc41.jar

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
CATALINA_BASE=/opt/tomcat-$CUSTOMCAT_NAME
START_TOMCAT=\$CATALINA_BASE/bin/startup.sh
STOP_TOMCAT=\$CATALINA_BASE/bin/shutdown.sh
PROG="georchestra-$CUSTOMCAT_NAME"
SHUTDOWN_WAIT=30

start(){
    echo -n "Starting \$PROG: "
	isrunning
	if [ "\$?" = 0 ]; then
		echo "\$PROG already running"
		return 0
	fi
	
	su -p -s /bin/sh tomcat \${START_TOMCAT}
	echo "done."
}

stop(){
    echo -n "Shutting down \$PROG: "

	if ! isrunning; then
		echo "\$PROG already stopped"
		return 0
	fi

	su -p -s /bin/sh tomcat \${STOP_TOMCAT}
	
	if isrunning ; then
		echo -n "Waiting \$PROG to stop..."
		sleep \$SHUTDOWN_WAIT
	fi
	
	if isrunning ; then
		echo "Still running, brutal kill !"
		start-stop-daemon --stop --pid \$pid --user "tomcat" --retry=TERM/20/KILL/5 >/dev/null
	else
		echo ""
	fi
	
	echo "done."
}

restart(){
   stop
   start
}

reload(){
   restart
}

isrunning() {
	findpid

	if [ "\$pid" = "" ]; then
		return 1
	elif [ "\$pid" -gt 0 ]; then
		return 0
	fi
}

findpid() {
	pid=""
	pid=\$(pgrep -U tomcat -f "^.*/bin/java.*catalina.base=\$CATALINA_BASE")

	# validate output of pgrep
	if ! [ "\$pid" = "" ] && ! [ "\$pid" -gt 0 ]; then
		log_failure_msg "Unable to determine if \$PROG is running"
		exit 1
	fi
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
