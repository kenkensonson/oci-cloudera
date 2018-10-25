# Need to set up the hosts as so:
# https://www.cloudera.com/documentation/enterprise/latest/topics/configure_network_names.html#configure_network_names

discovery () {
  # Utility
  hname=`host cdh-utility`
  echo "$hname" | head -n 1 | gawk '{print $1}'

  # Master
  endcheck=1
  i=0
  while [ "$endcheck" != 0 ]; do
    hname=`host cdh-master${i}`
    hchk=$?
    if [ "$hchk" = "1" ]; then
      endcheck="0"
    else
      echo "$hname" | head -n 1 | gawk '{print $1}'
      endcheck="1"
    fi
    i=$((i+1))
  done;

  # Worker
  endcheck=1
  i=0
  while [ "$endcheck" != 0 ]; do
    hname=`host cdh-worker${i}`
    hchk=$?
    if [ "$hchk" = "1" ]; then
      endcheck="0"
    else
      echo "$hname" | head -n 1 | gawk '{print $1}'
      endcheck="1"
    fi
    i=$((i+1))
  done;
}

cd /
discovery > host_list
cat host_list | grep worker >> workers

## Setup known_hosts entries for every machine in the cluster
for host in `cat host_list`; do
	key=`ssh-keyscan -t rsa -H $host 2>&1 | sed 1d | gawk '{print $3}'`;
	echo -e $host,$ip ecdsa-sha2-nistp256 $key >> /home/opc/.ssh/known_hosts;
done;
