#!/bin/bash

#Downloading tomcat 9.0.56
sudo apt update
sudo apt install default-jdk && sudo apt install wget
cd /opt/tomcat
sudo wget -P /opt/tomcat https://archive.apache.org/dist/tomcat/tomcat-9/v9.0.56/bin/apache-tomcat-9.0.56.tar.gz
sudo tar xf apache-tomcat-9.0.56.tar.gz
sudo rm /opt/tomcat/apache-tomcat-9.0.56.tar.gz
cd apache-tomcat-9.0.56
sudo chmod 777 *



#Creating tomcat user and group
sudo groupadd tomcat
sudo useradd -s /bin/bash -g tomcat -d /opt/tomcat tomcat
sudo usermod -a -G tomcat tomcat

#Changing ownership of tomcat files and directories
sudo chown -R tomcat /opt/tomcat/apache-tomcat-9.0.56/*

#Creating tomcat.service file and setclassath.sh
sudo chmod +x /opt/tomcat/apache-tomcat-9.0.56/bin/*.sh
cd /etc/systemd/system
sudo touch tomcat.service
sudo chmod 777 tomcat.service
echo "
[Unit]
Description=Apache Tomcat Web Application Container
After=network.target

[Service]
Type=oneshot

Environment=JAVA_HOME=/usr/lib/jvm/java-1.11.0-openjdk-amd64
Environment=JRE_HOME=/usr/lib/jvm/java-1.11.0-openjdk-amd64
Environment=CATALINA_PID=/opt/tomcat/temp/tomcat.pid
Environment=CATALINA_HOME=/opt/tomcat/apache-tomcat-9.0.56
Environment=CATALINA_BASE=/opt/tomcat/apache-tomcat-9.0.56
Environment='CATALINA_OPTS=-Xms512M -Xmx1024M -server -XX:+UseParallelGC'
Environment='JAVA_OPTS=-Djava.awt.headless=true -Djava.security.egd=file:/dev/./urandom'

ExecStart=/opt/tomcat/apache-tomcat-9.0.56/bin/startup.sh
ExecStop=/opt/tomcat/apache-tomcat-9.0.56/bin/shutdown.sh

User=tomcat
Group=tomcat
UMask=0007
RestartSec=10
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target" > tomcat.service
cd /opt/tomcat/apache-tomcat-9.0.56/bin
sudo touch setclasspath.sh
sudo chmod 777 setclasspath.sh
echo "
JAVA_HOME=/usr/lib/jvm/java-1.11.0-openjdk-amd64
JRE_HOME=/usr/lib/jvm/java-1.11.0-openjdk-amd64" > setclasspath.sh

#Starting Tomcat
sudo systemctl daemon-reload
sudo systemctl start tomcat
systemctl status tomcat
sudo systemctl enable tomcat

#Changing permissions
cd /opt/tomcat/apache-tomcat-9.0.56/conf
sudo chmod 006 *
cd /opt/tomcat/apache-tomcat-9.0.56/logs
sudo chmod 204 *

#Creating and running backup script once a week
cd /etc/cron.weekly
sudo touch backupScript.sh
sudo chmod 777 backupScript.sh
echo "
#!/bin/bash
sudo tar -cvf $HOME/BackUp_catalina/backUp-$(date +%d-%m).tar $CATALINA_HOME 
" > backupScript.sh

#Creating and running a script that checks Tomcat every hour
cd /etc/cron.hourly
sudo touch letMeCheckScript.sh
sudo chmod 777 letMeCheckScript.sh
echo "
#!/bin/bash

check_process() {
  [ '$1' = '' ]  && return 0
  [ `pgrep -l $1` ] && return 1 || return 0
}

while [ 1 ]; do 
  check_process 'tomcat'
  [ $? -eq 0 ] && echo 'Apache Tomcat is not running, restarting...' && `. $CATALINA_HOME/bin/startup.sh`
done" > letMeCheckScript.sh
