# Install Cloudera Management Service
## Set cdh_version to "5" to use latest version, otherwise custom version can be specified
#cdh_version="5.12.2"
cdh_version="5"
rpm --import http://archive.cloudera.com/cm5/redhat/7/x86_64/cm/RPM-GPG-KEY-cloudera
wget http://archive.cloudera.com/cm5/redhat/7/x86_64/cm/cloudera-manager.repo -O /etc/yum.repos.d/cloudera-manager.repo
if [ $cdh_version = "5" ]; then
  sleep .001
else
  sed -i "s/cm\/5/cm\/${cdh_version}/g" /etc/yum.repos.d/cloudera-manager.repo
fi
yum install -y oracle-j2sdk* cloudera-manager-daemons cloudera-manager-server

#echo -e "Copying (if exists) HDFS Data Tiering file from first Worker."
#scp -o BatchMode=yes -o StrictHostKeyChecking=no -i /home/opc/.ssh/id_rsa root@cdh-worker-1:/home/opc/hdfs_data_tiering.txt .
#if [ -f "hdfs_data_tiering.txt" ]; then
#  echo -e "HDFS Data Tiering file found!  Copying to Utility node."
#  scp -o BatchMode=yes -o StrictHostKeyChecking=no -i /home/opc/.ssh/id_rsa hdfs_data_tiering.txt root@cdh-utility-1:/home/opc/hdfs_data_tiering.txt
#fi
#echo -e "Starting CDH provisioning via SCM..."
## Invoke SCM bootstrapping and initialization
#ssh -o BatchMode=yes -o StrictHostKeyChecking=no -i /home/opc/.ssh/id_rsa opc@${utilfqdn} "sudo /home/opc/startup.sh"

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

echo "Installing Postgres, Python, Paramiko..."
yum install postgresql-server python-pip python-paramiko.noarch -y

echo "Configuring Postgres Database..."
bash /home/opc/initialize-postgresql.sh >> /var/log/postgresql_cdh_setup.log

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
	scm_lsn=`sudo netstat -tlpn | grep 7180`
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
