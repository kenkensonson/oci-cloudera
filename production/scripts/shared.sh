# Cloudera recommends setting /proc/sys/vm/swappiness to a maximum of 10. Current setting is 30. Use the sysctl command to change this setting at run time and edit /etc/sysctl.conf for this setting to be saved after a reboot. You can continue with installation, but Cloudera Manager might report that your hosts are unhealthy because they are swapping.
# Transparent Huge Page Compaction is enabled and can cause significant performance problems. Run "echo never > /sys/kernel/mm/transparent_hugepage/defrag" and "echo never > /sys/kernel/mm/transparent_hugepage/enabled" to disable this, and then add the same command to an init script such as /etc/rc.local so it will be set on system reboot.
#Starting with CDH 6, PostgreSQL-backed Hue requires the Psycopg2 version to be at least 2.5.4, see the documentation for more information. This warning can be ignored if hosts will not run CDH 6, or will not run Hue with PostgreSQL.

echo "Setting up resolve.conf..."
echo "search public0.cloudera.oraclevcn.com public1.cloudera.oraclevcn.com public2.cloudera.oraclevcn.com private0.cloudera.oraclevcn.com private1.cloudera.oraclevcn.com private2.cloudera.oraclevcn.com" > /etc/resolv.conf
echo "nameserver 169.254.169.254" >> /etc/resolv.conf

echo "Turning off the Firewall..."
service firewalld stop
chkconfig firewalld off

echo "Turning off selinux..."
sed -i.bak 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config
setenforce 0
