# Install instructions are here: https://www.cloudera.com/documentation/enterprise/6/6.0/topics/install_cm_cdh.html

# Step 1: Configure a Repository
wget https://archive.cloudera.com/cm6/6.0.1/redhat7/yum/cloudera-manager.repo -P /etc/yum.repos.d/
rpm --import https://archive.cloudera.com/cm6/6.0.1/redhat7/yum/RPM-GPG-KEY-cloudera

# Step 2: Install JDK
yum install -y oracle-j2sdk1.8

# Step 3: Install Cloudera Manager Server
yum install -y cloudera-manager-daemons cloudera-manager-agent cloudera-manager-server

# To do - TLS configuration
#JAVA_HOME=/usr/java/jdk1.8.0_141-cloudera /opt/cloudera/cm-agent/bin/certmanager setup --configure-services

# Step 4: Install Databases
yum install -y postgresql-server
yum install -y python-pip
pip install --upgrade pip
pip install psycopg2==2.7.5 --ignore-installed
