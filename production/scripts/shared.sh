echo "Setting up resolve.conf..."
echo "search public0.cloudera.oraclevcn.com public1.cloudera.oraclevcn.com public2.cloudera.oraclevcn.com private0.cloudera.oraclevcn.com private1.cloudera.oraclevcn.com private2.cloudera.oraclevcn.com" > /etc/resolv.conf
echo "nameserver 169.254.169.254" >> /etc/resolv.conf

echo "Turning off the Firewall..."
service firewalld stop
chkconfig firewalld off

echo "Turning off selinux..."
sed -i.bak 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config
setenforce 0

# Cloudera recommends setting /proc/sys/vm/swappiness to a maximum of 10.
echo "Setting swappiness to 10..."
sysctl vm.swappiness=10
echo "
# Required for Cloudera
vm.swappiness = 10
" >> /etc/sysctl.conf

# Transparent Huge Page Compaction is enabled and can cause significant performance problems.
echo "Turning off transparent hugepages..."

echo "#!/bin/bash
### BEGIN INIT INFO
# Provides:          disable-thp
# Required-Start:    $local_fs
# Required-Stop:
# X-Start-Before:
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Short-Description: Disable THP
# Description:       disables Transparent Huge Pages (THP) on boot
### END INIT INFO
echo 'never' > /sys/kernel/mm/transparent_hugepage/enabled
echo 'never' > /sys/kernel/mm/transparent_hugepage/defrag
" > /etc/init.d/disable-thp
chmod 755 /etc/init.d/disable-thp
service disable-thp start
chkconfig disable-thp on

# Starting with CDH 6, PostgreSQL-backed Hue requires the Psycopg2 version to be at least 2.5.4
yum install -y python-pip
pip install --upgrade pip
pip install psycopg2==2.7.5 --ignore-installed
