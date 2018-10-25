# Turn off selinux
sed -i.bak 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config
setenforce 0

# Set DNS to resolve all subnets
rm -f /etc/resolv.conf
echo "search public0.cloudera.oraclevcn.com public1.cloudera.oraclevcn.com public2.cloudera.oraclevcn.com private0.cloudera.oraclevcn.com private1.cloudera.oraclevcn.com private2.cloudera.oraclevcn.com bastion0.cloudera.oraclevcn.com bastion1.cloudera.oraclevcn.com bastion2.cloudera.oraclevcn.com" > /etc/resolv.conf
echo "nameserver 169.254.169.254" >> /etc/resolv.conf

# Turn off the firewall
echo "Turning off the Firewall..."
service firewalld stop
chkconfig firewalld off
