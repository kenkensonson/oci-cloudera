# Install instructions are here: https://www.cloudera.com/documentation/enterprise/6/6.0/topics/install_cm_cdh.html

# Step 1: Configure a Repository
wget https://archive.cloudera.com/cm6/6.0.1/redhat7/yum/cloudera-manager.repo -P /etc/yum.repos.d/
rpm --import https://archive.cloudera.com/cm6/6.0.1/redhat7/yum/RPM-GPG-KEY-cloudera

# Step 2: Install JDK
yum install -y oracle-j2sdk1.8

# Step 3: Install Cloudera Manager Server
yum install -y cloudera-manager-daemons cloudera-manager-agent cloudera-manager-server

# Step 4: Install Databases
yum install -y postgresql-server

yum install python-pip
pip install psycopg2==2.7.5 --ignore-installed

echo 'LC_ALL="en_US.UTF-8"' >> /etc/locale.conf
sudo su -l postgres -c "postgresql-setup initdb"

host all all 127.0.0.1/32 md5

systemctl enable postgresql
systemctl restart postgresql

#sudo -u postgres psql
#CREATE ROLE <user> LOGIN PASSWORD '<password>';
#CREATE DATABASE <database> OWNER <user> ENCODING 'UTF8';

# Step 5: Set up the Cloudera Manager Database
# Step 6: Install CDH and Other Software
# Step 7: Set Up a Cluster

VMSIZE=$(curl -L http://169.254.169.254/opc/v1/instance/metadata/shape)

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

echo "Installing CM API via PIP plus dependencies..."
pip install --upgrade pip
pip install pyopenssl ndg-httpsclient pyasn1
yum install libffi-devel -y
pip install "cm_api<20"

echo "Starting SCM Server..."
service cloudera-scm-server start

## Scrape hosts file to gather all IPs - this allows for dynamic number of hosts in cluster
for ip in `cat /home/opc/hosts | sed 1d | gawk '{print $1}'`; do
	if [ -z $cluster_host_ip ]; then
		cluster_host_ip="$ip"
	else
		cluster_host_ip="$cluster_host_ip,$ip"
	fi
done;

## Setup known_hosts entries for all hosts
for host in `cat /home/opc/hosts | gawk '{print $2}'`; do
	host_ip=`cat /home/opc/hosts | grep -w $host | gawk '{print $1}'`;
	host_key=`ssh-keyscan -t rsa -H $host 2>&1 | sed 1d | gawk '{print $3}'`;
	echo -e $host,$host_ip ecdsa-sha2-nistp256 $host_key >> ~/.ssh/known_hosts;
done;

## Check that SCM is running - the SCM startup takes some time
echo -n "Waiting for SCM server to be available [*"
scm_chk="1"
while [ "$scm_chk" != "0" ]; do
	scm_lsn=`netstat -tlpn | grep 7180`
	scm_chk=`echo -e $?`
	if [ "$scm_chk" = "0" ]; then
		echo -n "*] [OK]"
		echo -e "\n"
	else
		echo -n "*"
		sleep 1
	fi
done;

## Execute Python cluster setup
mkdir -p /log/cloudera
echo -e "Setup ready to execute... Running Cluster Initialization Script... (output will begin shortly)"
python /home/opc/cmx.py -a -n "$ClusterName" -u "$User" -m "$mip" -w "$cluster_host_ip" -c "$cmUser" -s "$cmPassword" -e -r "$EMAILADDRESS" -b "$BUSINESSPHONE" -f "$FIRSTNAME" -t "$LASTNAME" -o "$JOBROLE" -i "$JOBFUNCTION" -y "$COMPANY" -v "$VMSIZE" -k "$ssh_keypath"
