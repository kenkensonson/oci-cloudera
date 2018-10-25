#!/bin/bash

# Turn off selinux
if [ -f /etc/selinux/config ]; then
  selinuxchk=`sudo cat /etc/selinux/config | grep enforcing`
  selinux_chk=`echo -e $?`
  if [ $selinux_chk = "0" ]; then
    sudo sed -i.bak 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config
    sudo setenforce 0
  fi
fi
