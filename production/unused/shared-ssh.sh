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
host_discovery >> host_list
cat host_list | grep worker >> workers
