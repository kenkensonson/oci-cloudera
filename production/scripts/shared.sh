# Turn off selinux
sed -i.bak 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config
setenforce 0

# Set DNS to resolve all subnets
echo "search public0.cloudera.oraclevcn.com public1.cloudera.oraclevcn.com public2.cloudera.oraclevcn.com private0.cloudera.oraclevcn.com private1.cloudera.oraclevcn.com private2.cloudera.oraclevcn.com" > /etc/resolv.conf
echo "nameserver 169.254.169.254" >> /etc/resolv.conf

# Need to set up the hosts as so:
#https://www.cloudera.com/documentation/enterprise/latest/topics/configure_network_names.html#configure_network_names

echo "Turning off the Firewall..."
service firewalld stop
chkconfig firewalld off
