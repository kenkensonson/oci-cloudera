echo "Turning off the Firewall..."
service firewalld stop
chkconfig firewalld off

echo "Turning off selinux..."
sed -i.bak 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config
setenforce 0
