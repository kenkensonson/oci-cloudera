#!/bin/bash

echo "Turning off the Firewall..."
service firewalld stop
chkconfig firewalld off

echo -e "Installing Docker..."
yum -y install docker
systemctl start docker

echo -e "Downloading, Extracting and Starting Cloudera Docker Container..."
docker run -d --hostname=quickstart.cloudera --privileged=true -t -i -p 8888:8888 -p 7180:7180 -p 80:80 cloudera/quickstart:latest /usr/bin/docker-quickstart

echo -e "Waiting 120 seconds for the container to start..."
sleep 120

echo -e "Starting Cloudera Manager..."
container=`docker ps | sed 1d | gawk '{print $1}'`
docker exec -it ${container} /home/cloudera/cloudera-manager --express

echo -e "Adding Cloudera user..."
useradd  cloudera
mkdir /home/cloudera/.ssh
cp /home/opc/.ssh/authorized_keys /home/cloudera/.ssh/
chown cloudera:cloudera -R /home/cloudera
usermod -aG wheel cloudera
