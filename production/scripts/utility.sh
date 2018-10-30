# Install instructions are here: https://www.cloudera.com/documentation/enterprise/6/6.0/topics/install_cm_cdh.html

# Step 1: Configure a Repository
wget https://archive.cloudera.com/cm6/6.0.1/redhat7/yum/cloudera-manager.repo -P /etc/yum.repos.d/
rpm --import https://archive.cloudera.com/cm6/6.0.1/redhat7/yum/RPM-GPG-KEY-cloudera

# Step 2: Install JDK
yum install -y oracle-j2sdk1.8

# Step 3: Install Cloudera Manager Server
yum install -y cloudera-manager-daemons cloudera-manager-agent cloudera-manager-server

# I wonder if turning off auto TLS will resolve the hostname/fqdn issues I'm seeing
#JAVA_HOME=/usr/java/jdk1.8.0_141-cloudera /opt/cloudera/cm-agent/bin/certmanager setup --configure-services

# Step 4: Install Databases
yum install -y postgresql-server
yum install -y python-pip
pip install --upgrade pip
pip install psycopg2==2.7.5 --ignore-installed

# Step 4.1: Make sure that LC_ALL is set to en_US.UTF-8 and initialize the database
echo 'LC_ALL="en_US.UTF-8"' >> /etc/locale.conf
su -l postgres -c "postgresql-setup initdb"

# Step 4.2: Enable MD5 authentication.
ip=$(hostname -I)
ip=${ip%?}
echo "# TYPE  DATABASE        USER            ADDRESS                 METHOD
local   all             all                                     peer
host    all             all             ${ip}/32             md5
host    all             all             127.0.0.1/32            ident
host    all             all             ::1/128                 ident
" > /var/lib/pgsql/data/pg_hba.conf

echo "listen_addresses = '*'
" >> /var/lib/pgsql/data/postgresql.conf

# Step 4.4: Configure the PostgreSQL server to start at boot.
systemctl enable postgresql
systemctl restart postgresql

# Step 5: Set up the Cloudera Manager Database
for DATABASENAME in scm amon rman hue metastore sentry nav navms oozie; do
  sudo -u postgres psql -c "CREATE ROLE ${DATABASENAME} LOGIN PASSWORD 'password';"
  sudo -u postgres psql -c "CREATE DATABASE ${DATABASENAME} OWNER ${DATABASENAME} ENCODING 'UTF8';"
  sudo -u postgres psql -c "ALTER DATABASE ${DATABASENAME} SET standard_conforming_strings=off;"
done
/opt/cloudera/cm/schema/scm_prepare_database.sh postgresql scm scm password

# Step 6: Install CDH and Other Software
systemctl start cloudera-scm-server

# Step 7: Set Up a Cluster
VMSIZE=$(curl http://169.254.169.254/opc/v1/instance/shape)
ClusterName="TestCluster"
cmUser="cdhadmin"
cmPassword="somepassword"

# master[0-99]
# worker[0-99]

 python utility.py \
   --highavailable \
   -n "$ClusterName" \
   -u "$User" \
   -m "$mip" -w \
   "$cluster_host_ip" \
   -c "$cmUser" \
   -s "$cmPassword" \
   --accept-eula \
   -v "$VMSIZE" \
   -k "$ssh_keypath"
