#!/bin/bash

echo "Turning off the Firewall..."
service firewalld stop
chkconfig firewalld off

echo -e "Installing Docker..."
yum -y install docker
systemctl start docker

echo -e "Downloading Cloudera Docker Container..."
cd /
filename=cloudera-quickstart-vm-5.13.0-0-beta-docker
wget https://downloads.cloudera.com/demo_vm/docker/${filename}.tar.gz
tar -zxvf ${filename}.tar.gz
cd ${filename}
docker import ${filename}.tar

echo -e "Starting Cloudera Docker Container..."
docker run -d --hostname=quickstart.cloudera --privileged=true -t -i -p 8888:8888 -p 7180:7180 -p 80:80 cloudera/quickstart:latest /usr/bin/docker-quickstart

echo -e "Waiting 120 seconds for the container to start..."
sleep 120

echo -e "Starting Cloudera Manager..."
container=`docker ps | sed 1d | gawk '{print $1}'`
docker exec -it ${container} /home/cloudera/cloudera-manager --express

echo -e "Adding Cloudera user..."
useradd -s /bin/bash cloudera
mkdir -p /home/cloudera/.ssh
cp /home/opc/.ssh/authorized_keys /home/cloudera/.ssh/
chown cloudera:cloudera -R /home/cloudera
echo "cloudera    ALL=(ALL)       ALL" >> /etc/sudoers
