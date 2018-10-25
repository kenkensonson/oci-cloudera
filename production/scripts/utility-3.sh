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
