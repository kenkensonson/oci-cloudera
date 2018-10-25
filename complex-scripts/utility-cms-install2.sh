## Invoke CMS installer
install_success="1"
while [ $install_success = "1" ]; do
  ssh -o BatchMode=yes -o StrictHostKeyChecking=no -i /home/opc/.ssh/id_rsa opc@${utilfqdn} "sudo /home/opc/cms_install.sh"
  install_success=`echo -e $?`
  sleep 10
done
echo -e "CDH Manager Setup Complete."
echo -e "Copying (if exists) HDFS Data Tiering file from first Worker."
scp -o BatchMode=yes -o StrictHostKeyChecking=no -i /home/opc/.ssh/id_rsa root@cdh-worker-1:/home/opc/hdfs_data_tiering.txt .
if [ -f "hdfs_data_tiering.txt" ]; then
  echo -e "HDFS Data Tiering file found!  Copying to Utility node."
  scp -o BatchMode=yes -o StrictHostKeyChecking=no -i /home/opc/.ssh/id_rsa hdfs_data_tiering.txt root@cdh-utility-1:/home/opc/hdfs_data_tiering.txt
fi
echo -e "Starting CDH provisioning via SCM..."

## Invoke SCM bootstrapping and initialization
ssh -o BatchMode=yes -o StrictHostKeyChecking=no -i /home/opc/.ssh/id_rsa opc@${utilfqdn} "sudo /home/opc/startup.sh"
echo -e "--------------------------------------------------------------------"
echo -e "---------------------CLUSTER SETUP COMPLETE-------------------------"
echo -e "--------------------------------------------------------------------"

if [ -d post-setup-scripts ]; then
  echo -e "---Running Post Installation Scripts---"
  for script in `ls post-setup-scripts/`; do
    sh post-setup-scripts/${script}
  done;
fi
