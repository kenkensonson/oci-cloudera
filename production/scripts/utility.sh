# Install instructions are here: https://www.cloudera.com/documentation/enterprise/6/6.0/topics/install_cm_cdh.html

# Step 1: Configure a Repository
wget https://archive.cloudera.com/cm6/6.0.1/redhat7/yum/cloudera-manager.repo -P /etc/yum.repos.d/
rpm --import https://archive.cloudera.com/cm6/6.0.1/redhat7/yum/RPM-GPG-KEY-cloudera

# Step 2: Install JDK
yum install -y oracle-j2sdk1.8

# Step 3: Install Cloudera Manager Server
yum install -y cloudera-manager-daemons cloudera-manager-agent cloudera-manager-server
JAVA_HOME=/usr/java/jdk1.8.0_141-cloudera /opt/cloudera/cm-agent/bin/certmanager setup --configure-services

# Step 4: Install Databases
yum install -y postgresql-server
yum install -y python-pip
pip install --upgrade pip
pip install psycopg2==2.7.5 --ignore-installed

# Step 4.1: Make sure that LC_ALL is set to en_US.UTF-8 and initialize the database
echo 'LC_ALL="en_US.UTF-8"' >> /etc/locale.conf
su -l postgres -c "postgresql-setup initdb"

# Step 4.2: Enable MD5 authentication.
CONF_FILE=/var/lib/pgsql/data/pg_hba.conf
sed -i '/host.*127.*ident/i \host    all         all         127.0.0.1/32          md5  \ ' ${CONF_FILE}
#sed -e '/^listen_addresses\s*=/d' -i ${CONF_FILE}

# Step 4.3: Configure settings to ensure your system performs as expected.
#/var/lib/pgsql/data/postgresql.conf
#sed -e '/^max_connections\s*=/d' -i "$CONF_FILE"
#sed -e '/^shared_buffers\s*=/d' -i "$CONF_FILE"
#sed -e '/^standard_conforming_strings\s*=/d' -i "$CONF_FILE"

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

## Execute Python cluster setup
VMSIZE=$(curl http://169.254.169.254/opc/v1/instance/shape)
ClusterName="TestCluster"
cmUser="cdhadmin"
cmPassword="somepassword"
EMAILADDRESS="someguy@oracle.com"
BUSINESSPHONE="8675309"
FIRSTNAME="Big"
LASTNAME="Data"
JOBROLE="root"
JOBFUNCTION="root"
COMPANY="Oracle"

python /home/opc/cmx.py \
  -a \
  -n "$ClusterName" \
  -u "$User" \
  -m "$mip" -w \
  "$cluster_host_ip" \
  -c "$cmUser" \
  -s "$cmPassword" \
  -e \
  -r "$EMAILADDRESS" \
  -b "$BUSINESSPHONE" \
  -f "$FIRSTNAME" \
  -t "$LASTNAME" \
  -o "$JOBROLE" \
  -i "$JOBFUNCTION" \
  -y "$COMPANY" \
  -v "$VMSIZE" \
  -k "$ssh_keypath"
